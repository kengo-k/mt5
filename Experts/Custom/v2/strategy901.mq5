/**
 * 長期の時間足を想定したストラテジー
 * 長期ではトレンドが継続しやすいはずという考えにもとづき25MAを使用しブレイクと同時にエントリーし再度反対方向にブレイクしたときにクローズする。
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy901";
const long MAGIC_NUMBER = 1;

input double VOLUME = 0.1;
input int MA_PERIOD = 25;
input int TP = 200;

class Config {
public:

   double volume;
   int maPeriod;
   int tp;

   Config():
      volume(VOLUME)
      , maPeriod(MA_PERIOD)
      , tp(TP) {}
};

class Context {
public:
   int maHandle;
   double ma[];
};

GridManager __gridManager(0);
Config __config;
Context __context;

// 新規注文キュー
RequestContainer __newOrderQueue;
// 決済注文キュー
RequestContainer __closeOrderQueue;
// 新規注文の生成を判断するための足
Bar __createNewOrderBar(PERIOD_CURRENT);
// 新規注文キューを処理するための足
Bar __sendNewOrderBar(PERIOD_M5);
// 決済注文の生成を判断するための足
Bar __createCloseOrderBar(PERIOD_CURRENT);
// 決済注文キューを処理するための足
Bar __sendCloseOrderBar(PERIOD_M5);

int OnInit() {
   __LOGGER__ = new Logger(EA_NAME);
   __context.maHandle = iMA(Symbol(), PERIOD_CURRENT, __config.maPeriod, 0, MODE_SMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __createCloseOrderBar.onBarCreated(createCloseOrder);
   __sendCloseOrderBar.onBarCreated(sendCloseOrder);
   __createNewOrderBar.onBarCreated(createNewOrder);
   __sendNewOrderBar.onBarCreated(sendNewOrder);
}

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規注文のリクエストを生成しキューに追加する
 */
ENUM_ENTRY_COMMAND getNextCommand() {
   
   MqlRates prices[];
   ArraySetAsSeries(prices, false);
   CopyRates(Symbol(), PERIOD_CURRENT, 0, 3, prices);
   MqlRates currentPrice = prices[2];
   MqlRates latestPrice = prices[1];
   MqlRates prevPrice = prices[0];
   
   CopyBuffer(__context.maHandle, 0, 0, 3, __context.ma);
   double currentMa = __context.ma[2];
   double latestMa = __context.ma[1];
   double prevMa = __context.ma[0];
   
   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (prevPrice.close < prevMa && latestPrice.close > latestMa && currentPrice.open > currentMa) {
      command = ENTRY_COMMAND_BUY;
   }
   if (prevPrice.close > prevMa && latestPrice.close < latestMa && currentPrice.open < currentMa) {
      command = ENTRY_COMMAND_SELL;
   }
   return command;
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規注文のリクエストを生成しキューに追加する
 */
void createNewOrder() {
   ENUM_ENTRY_COMMAND command = getNextCommand();
   if (command == ENTRY_COMMAND_NOOP) {
      return;
   }
   int posCount = PositionsTotal();
   if (posCount > 0) {
      ulong posTicket = PositionGetTicket(0);
      if (posTicket) {
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         if (
            (type == POSITION_TYPE_BUY && command == ENTRY_COMMAND_BUY)
               || (type == POSITION_TYPE_SELL && command == ENTRY_COMMAND_SELL)         
         ) {
            return;
         }
      }
   }
   if (command == ENTRY_COMMAND_BUY) {
      Request* req = __newOrderQueue.createRequest();
      Order::createBuyRequest(req.item, -1, __config.tp, __config.volume, MAGIC_NUMBER);
      __newOrderQueue.add(req);
   }
   if (command == ENTRY_COMMAND_SELL) {
      Request* req = __newOrderQueue.createRequest();
      Order::createSellRequest(req.item, -1, __config.tp, __config.volume, MAGIC_NUMBER);
      __newOrderQueue.add(req);
   }
}

/**
 * 新規注文キューを処理して新規注文リクエストを送信する
 */
void sendNewOrder() {
   __gridManager.sendOrdersFromQueue(__newOrderQueue, false);
}

void createCloseOrder() {
   ENUM_ENTRY_COMMAND command = getNextCommand();
   if (command == ENTRY_COMMAND_NOOP) {
      return;
   }
   int posCount = PositionsTotal();
   if (posCount > 0) {
      ulong posTicket = PositionGetTicket(0);
      if (posTicket) {
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         if (
            (type == POSITION_TYPE_BUY && command == ENTRY_COMMAND_SELL)
               || (type == POSITION_TYPE_SELL && command == ENTRY_COMMAND_BUY)
         ) {
            Request *req = __closeOrderQueue.createRequest();
            Order::createCloseRequest(req.item, posTicket, MAGIC_NUMBER);
            __closeOrderQueue.add(req);            
         }
      }
   }
}

void sendCloseOrder() {
   __gridManager.sendOrdersFromQueue(__closeOrderQueue, false);
}