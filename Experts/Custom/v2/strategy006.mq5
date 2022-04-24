#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Config/Config004.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Context/ContextHelper.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>

const string EA_NAME = "strategy006";
const long MAGIC_NUMBER = 1;
input double VOLUME = 0.1;
input double TP = 30;
input int LONG_MA_PERIOD = 100;
input int LONG_LONG_MA_PERIOD = 200;
input int GRID_SIZE = 30;
input int STOP_DAY = 30;

GridManager __gridManager(GRID_SIZE);

Context002 __contextMain;
Context002 __contextSub;

Config004 __config = Config004Factory::create(
   EA_NAME
   , MAGIC_NUMBER
   , VOLUME
   , TP
   , LONG_MA_PERIOD
   , LONG_LONG_MA_PERIOD
   , 30
   , PERIOD_M1
);

Logger logger(__config.eaName);
// 新規注文キュー
RequestContainer __newOrderQueue;
// ストップ注文キュー
RequestContainer __stopOrderQueue;
// 新規注文の生成を判断するための足
Bar __createNewOrderBar(PERIOD_CURRENT);
// 新規注文キューを処理するための足
Bar __sendNewOrderBar(PERIOD_M5);
// ストップ注文の生成を判断するための足
Bar __createStopOrderBar(PERIOD_D1);
// ストップ注文キューを処理するための足
Bar __sendStopOrderBar(PERIOD_M5);


int OnInit() {
   ContextHelper::initContext(__contextMain, __contextSub, __config);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   // ストップ注文キューを随時処理する
   __sendStopOrderBar.onBarCreated(sendStopOrder);
   // 保持しているポジションが一定期間を過ぎたら強制決済する
   __createStopOrderBar.onBarCreated(createStopOrder);
   // 指定価格に到達したら指値注文を注文キューに追加する
   __createNewOrderBar.onBarCreated(createNewOrder);
   // 新規注文キューを随時処理する
   __sendNewOrderBar.onBarCreated(sendNewOrder);
}

void OnDeinit(const int reason) {}

double OnTester() {
   return Util::calcWinRatio();
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規注文のリクエストを生成しキューに追加する
 */
void createNewOrder() {

   CopyBuffer(__contextMain.longMaHandle, 0, 0, 2, __contextMain.longMA);
   CopyBuffer(__contextMain.longlongMaHandle, 0, 0, 2, __contextMain.longlongMA);

   double longMa = __contextMain.longMA[0];
   double longlongMa = __contextMain.longlongMA[0];

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (longMa > longlongMa) {
      command = ENTRY_COMMAND_BUY;
   } else {
      command = ENTRY_COMMAND_SELL;
   }

   // 次のグリッド価格を取得する
   double gridPrice = __gridManager.getTargetGridPrice(command);
   Request* req = __newOrderQueue.createRequest();
   // 指値注文(TP付き)のリクエストを生成する
   Order::createLimitRequest(command, req.item, gridPrice, __config.volume, -1, __config.tp, __config.magicNumber);
   // 長期間約定しない注文が残り続けないように一定期間で自動で削除されるようにする
   req.item.type_time = ORDER_TIME_SPECIFIED;
   req.item.expiration = Util::addSec(Util::addDay(Util::toDate(TimeCurrent()), 8), -1);
   // 注文をキューに入れる(注文処理用の時間足で処理される ※00:00前後は市場がcloseしているため時間をずらしながらリトライする)
   __newOrderQueue.add(req);
}

/**
 * 新規注文キューを処理して新規注文リクエストを送信する
 */
void sendNewOrder() {
   MqlTradeResult result;
   int orderCount = __newOrderQueue.count();
   for (int i = orderCount - 1; i >= 0; i--) {
      // キューからリクエストを取得する
      Request *req = __newOrderQueue.get(i);
      double price = req.item.price;
      ENUM_ORDER_TYPE type = req.item.type;
      // リクエストの価格がすでに使われている場合(買い/売りそれぞれ同時に一つまで)は
      // キューから削除し発注せずに終了する
      if (__gridManager.isGridPriceUsed(type, price)) {
         __newOrderQueue.remove(i);
         continue;
      }
      // 発注処理
      ZeroMemory(result);
      logger.logRequest(req.item);
      bool isSended = OrderSend(req.item, result);
      logger.logResponse(result, isSended);
      // 発注結果確認処理
      // ・成功時はキューから削除。
      // ・失敗した場合は次回の送信まで持ち越し
      // ・致命的エラーの場合はシステム終了
      bool isValid = false;
      if (result.retcode == TRADE_RETCODE_DONE) {
         isValid = true;
      }
      // 市場が開いてない場合は問題なしなのでパスする
      if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
         isValid = true;
      }
      // 現在値とグリッド価格が近すぎる場合は注文が通らないことが起こり得るのでパスする
      if (result.retcode == TRADE_RETCODE_INVALID_PRICE) {
         isValid = true;
      }
      // 想定外のエラーのため念のためシステム停止
      if (!isValid) {
         ExpertRemove();
      }

      __newOrderQueue.remove(i);
   }
}

/**
 * 一定期間以上保持しているポジションが存在する場合、
 * 損失を確定させるために損切り注文のリクエストをキューに送信する
 */
void createStopOrder() {
   int posCount = PositionsTotal();
   // 現在保持しているすべてのポジションを調べる
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         // 現在時刻を取得
         datetime currentTime = TimeCurrent();
         // 指値注文の値段に到達してポジションが建った時刻を取得
         datetime posTime = (datetime) PositionGetInteger(POSITION_TIME);
         // 上記２つの時刻からポジション保持期間を算出
         long diffSec = currentTime - posTime;
         int diffDay = Util::getDiffDay(currentTime, posTime);
         double profit = PositionGetDouble(POSITION_PROFIT);
         printf("3: profit(#%d): %f", posTicket, profit);
         // ポジション保持期間が閾値以上で利益が出ていないポジションは場合は損切り用のキューにリクエストを追加
         if (diffDay > STOP_DAY && profit < 0) {
            Request* req = __stopOrderQueue.createRequest();
            Order::createCloseRequest(req.item, posTicket, __config.magicNumber);
            __stopOrderQueue.add(req);
         }
      }
   }
}

/**
 * 損切り注文キューを処理して新規注文リクエストを送信する
 */
void sendStopOrder() {
   MqlTradeResult result;
   int orderCount = __stopOrderQueue.count();
   for (int i = orderCount - 1; i >= 0; i--) {
      // キューからリクエストを取得する
      Request *req = __stopOrderQueue.get(i);
      // 発注処理
      ZeroMemory(result);
      logger.logRequest(req.item);
      bool isSended = OrderSend(req.item, result);
      logger.logResponse(result, isSended);
      // 発注結果確認処理
      // ・成功時はキューから削除。
      // ・失敗した場合は次回の送信まで持ち越し
      // ・致命的エラーの場合はシステム終了
      bool isValid = false;
      if (result.retcode == TRADE_RETCODE_DONE) {
         isValid = true;
      }
      // 市場が開いてない場合は問題なしなのでパスする
      if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
         isValid = true;
      }
      // 想定外のエラーのため念のためシステム停止
      if (!isValid) {
         ExpertRemove();
      }

      __stopOrderQueue.remove(i);
   }
}