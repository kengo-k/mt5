/**
 * グリッドトレードのバリエーション形
 * シンプルにSL/TPを設定する
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>

const string EA_NAME = "strategy008";
const long MAGIC_NUMBER = 1;
input double VOLUME = 0.1;
input int SL = 100;
input int TP = 25;
input int LONG_MA_PERIOD = 5;
input int LONG_LONG_MA_PERIOD = 15;
input int GRID_SIZE = 10;

class Config {
public:

   // 取引量
   double volume;
   int sl;
   int tp;
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
   // グリッドの大きさ(pips)
   int gridSize;
   // 発注に使用する時間足
   ENUM_TIMEFRAMES orderPeriod;

   Config():
      volume(VOLUME)
      , tp(TP)
      , sl(SL)
      , longMaPeriod(LONG_MA_PERIOD)
      , longlongMaPeriod(LONG_LONG_MA_PERIOD)
      , gridSize(GRID_SIZE)
      , orderPeriod(PERIOD_M1) {}
};

class Context {
public:
   int longMaHandle;
   int longlongMaHandle;
   double longMA[];
   double longlongMA[];
};


Logger logger(EA_NAME);
Config __config;
Context __context;
GridManager __gridManager(__config.gridSize);

// 新規注文キュー
RequestContainer __newOrderQueue;
// 更新注文キュー
RequestContainer __updateOrderQueue;
// ストップ注文キュー
RequestContainer __stopOrderQueue;
// 新規注文の生成を判断するための足
Bar __createNewOrderBar(PERIOD_CURRENT);
// 新規注文キューを処理するための足
Bar __sendNewOrderBar(PERIOD_M5);

int OnInit() {
   __context.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __createNewOrderBar.onBarCreated(createNewOrder);
   // 新規注文キューを随時処理する
   __sendNewOrderBar.onBarCreated(sendNewOrder);
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規注文のリクエストを生成しキューに追加する
 */
void createNewOrder() {

   CopyBuffer(__context.longMaHandle, 0, 0, 2, __context.longMA);
   CopyBuffer(__context.longlongMaHandle, 0, 0, 2, __context.longlongMA);

   double longMa = __context.longMA[0];
   double longlongMa = __context.longlongMA[0];

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
   Order::createLimitRequest(command, req.item, gridPrice, __config.volume, __config.sl, __config.tp, MAGIC_NUMBER);
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
