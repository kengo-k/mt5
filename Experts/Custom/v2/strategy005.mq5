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

const string EA_NAME = "strategy005";;
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
   // ローソク足が新しく生成されているか数を確認
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

void OnTradeTransaction(const MqlTradeTransaction &tran, const MqlTradeRequest &request, const MqlTradeResult &result) {
   __gridManager.processTransaction(tran, request, result);
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規オーダーを生成しキューに追加する
 */
void createOrder() {
   MqlRates ohlc = Chart::getLatestOHLC(PERIOD_CURRENT);
   //printf("ohlc: %f, %f, %f, %f!!!!", ohlc.open, ohlc.high, ohlc.low, ohlc.close);
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
   if (!__gridManager.isGridPriceUsed(gridPrice)) {
      OrderContainer* orderContainer = __gridManager.createOrderContainer();
      Order::createLimitRequest(command, orderContainer.request, gridPrice, __config.volume, -1, __config.tp, __config.magicNumber);
      __gridManager.addOrder(orderContainer);
   }   
}

/**
 * 生成したオーダーのキューからリクエストを送信する
 */
void sendOrder() {
   MqlTradeResult result;
   int orderCount = __gridManager.getOrderCount();
   for (int i = orderCount - 1; i >= 0; i--) {
      ZeroMemory(result);
      OrderContainer *order = __gridManager.getOrder(i);
      logger.logRequest(order.request);
      bool isSended = OrderSend(order.request, result);
      logger.logResponse(result, isSended);
      
      bool isValid = false;
      if (result.retcode == TRADE_RETCODE_DONE) {
         isValid = true;
      }
      // 市場が開いてない場合は問題なしなのでそのまま通す
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
      if (isSended) {
         __gridManager.deleteOrder(i);
      }      
   }
}
