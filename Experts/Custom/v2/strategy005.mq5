/**
 * エントリ:
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Config/Config004.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Context/ContextHelper.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>

const string EA_NAME = "strategy005";
const long MAGIC_NUMBER = 1;
input double VOLUME = 0.1;
input double TP = 30;
input int LONG_MA_PERIOD = 100;
input int LONG_LONG_MA_PERIOD = 200;
input int GRID_SIZE = 30;

GridManager __gridManager(
   // グリッドのサイズ
   GRID_SIZE,
   // グリッドの基準価格を取得する年月
   "202101"
);

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

int OnInit() {
   string symbol = Symbol();
   string period = Util::getPeriodName(Period());
   double unit = Util::getUnit();
   logger.logWrite(LOG_LEVEL_INFO, StringFormat("%s start. %s, %s, unit: %f", EA_NAME, symbol, period, unit));
   ContextHelper::initContext(__contextMain, __contextSub, __config);
   return(INIT_SUCCEEDED);
}

int mainBarCount = -1;
int orderBarCount = -1;

void OnTick() {

   int newMainBarCount = Bars(Symbol(), PERIOD_CURRENT);
   int newOrderBarCount = Bars(Symbol(), __config.orderPeriod);
   if (mainBarCount == -1) {
      mainBarCount = newMainBarCount;
   }
   if (orderBarCount == -1) {
      orderBarCount = newOrderBarCount;
   }
   if (newMainBarCount > mainBarCount) {
      createOrder();
      mainBarCount = newMainBarCount;
   }
   if (newOrderBarCount > orderBarCount) {
      sendOrder();
      orderBarCount = newOrderBarCount;
   }
}

void OnDeinit(const int reason) {}

double OnTester() {
   return Util::calcWinRatio();
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規オーダーを生成しキューに追加する
 */
void createOrder() {

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
   OrderContainer* orderContainer = __gridManager.createOrderContainer();
   // 指値注文(TP付き)のリクエストを生成する
   Order::createLimitRequest(command, orderContainer.request, gridPrice, __config.volume, -1, __config.tp, __config.magicNumber);
   // 長期間約定しない注文が残り続けないように一定期間で自動で削除されるようにする
   orderContainer.request.type_time = ORDER_TIME_SPECIFIED;
   orderContainer.request.expiration = Util::addSec(Util::addDay(Util::toDate(TimeCurrent()), 8), -1);
   // 注文をキューに入れる(注文処理用の時間足で処理される ※00:00前後は市場がcloseしているため時間をずらしながらリトライする)
   __gridManager.addOrder(orderContainer);
}

/**
 * 生成したオーダーのキューからリクエストを送信する
 */
void sendOrder() {
   MqlTradeResult result;
   int orderCount = __gridManager.getOrderCount();
   for (int i = orderCount - 1; i >= 0; i--) {
      // キューからリクエストを取得する
      OrderContainer *order = __gridManager.getOrder(i);
      double price = order.request.price;
      ENUM_ORDER_TYPE type = order.request.type;
      // リクエストの価格がすでに使われている場合(買い/売りそれぞれ同時に一つまで)は
      // キューから削除し発注せずに終了する
      if (__gridManager.isGridPriceUsed(type, price)) {
         __gridManager.deleteOrder(i);
         continue;
      }
      // 発注処理
      ZeroMemory(result);
      logger.logRequest(order.request);
      bool isSended = OrderSend(order.request, result);
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

      __gridManager.deleteOrder(i);
   }
}
