/**
 * 902の改善を目指したバージョン
 * 新しい足が出るのを待っては遅いので時間足自体は長期を使うが取引タイミングは短期の足を使うことで
 * ブレイクしたあとの新しい足ではなくブレイクした瞬間にエントリする
 */
#include <Generic/HashSet.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Common/GridManager.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy902";
const long MAGIC_NUMBER = 1;

input double VOLUME = 0.1;
input int MA_PERIOD = 25;
input int TP = 200;
input double MIN_STOP_WIDTH = 200;

class Config {
public:

   double volume;
   int maPeriod;
   int tp;
   double minStopWidth;
   ENUM_TIMEFRAMES orderPeriod;

   Config():
      volume(VOLUME)
      , maPeriod(MA_PERIOD)
      , tp(TP)
      , minStopWidth(MIN_STOP_WIDTH)
      , orderPeriod(PERIOD_H1) {}
};

class Context {
public:
   int maHandle;
   double ma[];
};

GridManager __gridManager(0);
Config __config;
Context __context;

// 新規注文を出した年月を格納するデータ
// 同月内で複数回の新規エントリをさせないために使用する
CHashSet<string> usedMonth;

// 新規注文キュー
RequestContainer __newOrderQueue;
// 決済注文キュー
RequestContainer __closeOrderQueue;
// 新規注文の生成を判断するための足
Bar __createNewOrderBar(__config.orderPeriod);
// 新規注文キューを処理するための足
Bar __sendNewOrderBar(PERIOD_M1);
// 決済注文の生成を判断するための足
Bar __createCloseOrderBar(__config.orderPeriod);
// 決済注文キューを処理するための足
Bar __sendCloseOrderBar(PERIOD_M1);

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

void OnTradeTransaction(const MqlTradeTransaction &tran, const MqlTradeRequest &request, const MqlTradeResult &result) {
   if (tran.type == TRADE_TRANSACTION_DEAL_ADD) {
      if (HistoryDealSelect(tran.deal)) {
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY) HistoryDealGetInteger(tran.deal, DEAL_ENTRY);
         if (entry == DEAL_ENTRY_IN) {
            string currentMonth = Util::getCurrentMonth();
            usedMonth.Add(currentMonth);
         }
      }
   }
}

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

ENUM_ENTRY_COMMAND getNextCommand() {

   MqlRates prices[];
   ArraySetAsSeries(prices, false);
   CopyRates(Symbol(), __config.orderPeriod, 0, 3, prices);
   MqlRates latestPrice = prices[1];
   MqlRates prevPrice = prices[0];

   // メイン足の現在のローソクを取得
   MqlRates currentPeriodPrice = Chart::getCurrentOHLC(PERIOD_CURRENT);

   CopyBuffer(__context.maHandle, 0, 0, 1, __context.ma);
   double currentMa = __context.ma[0];

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (currentPeriodPrice.open < currentMa && prevPrice.close < currentMa && latestPrice.close > currentMa) {
      command = ENTRY_COMMAND_BUY;
   }
   if (currentPeriodPrice.open > currentMa && prevPrice.close > currentMa && latestPrice.close < currentMa) {
      command = ENTRY_COMMAND_SELL;
   }
   return command;
}

void createNewOrder() {
   ENUM_ENTRY_COMMAND command = getNextCommand();
   if (command == ENTRY_COMMAND_NOOP) {
      return;
   }
   int posCount = PositionsTotal();
   if (posCount > 0) {
      return;
   }

   string currentMonth = Util::getCurrentMonth();
   if (usedMonth.Contains(currentMonth)) {
      return;
   }

   if (command == ENTRY_COMMAND_BUY) {
      Request* req = __newOrderQueue.createRequest();
      double sl = getSL(command);
      if (sl > 0) {
         Order::createBuyRequest(req.item, getSL(command), -1, __config.volume, MAGIC_NUMBER, false);
         __newOrderQueue.add(req);
      }
   }
   if (command == ENTRY_COMMAND_SELL) {
      Request* req = __newOrderQueue.createRequest();
      double sl = getSL(command);
      if (sl > 0) {
         Order::createSellRequest(req.item, getSL(command), -1, __config.volume, MAGIC_NUMBER, false);
         __newOrderQueue.add(req);
      }
   }
}

/**
 * 新規注文キューを処理して新規注文リクエストを送信する
 */
void sendNewOrder() {
   __gridManager.sendOrdersFromQueue(__newOrderQueue, false);
}

void createCloseOrder() {
   int posCount = PositionsTotal();
   if (posCount > 0) {
      ENUM_ENTRY_COMMAND command = getNextCommand();
      if (command == ENTRY_COMMAND_NOOP) {
         return;
      }
      ulong posTicket = PositionGetTicket(0);
      if (posTicket) {
         datetime positionTime = (datetime) PositionGetInteger(POSITION_TIME);
         datetime currentTime = TimeCurrent();
         if (Util::isSameMonth(positionTime, currentTime)) {
            return;
         }
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

double getSL(ENUM_ENTRY_COMMAND command) {

   MqlRates prices[];
   ArraySetAsSeries(prices, false);
   CopyRates(Symbol(), PERIOD_CURRENT, 0, 1, prices);
   MqlRates currentPrice = prices[0];

   double unit = Util::getUnit();
   double sl;
   if (command == ENTRY_COMMAND_BUY) {
      sl =  currentPrice.low;
      double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double diff = ask - sl;
      double diffPips = diff / unit;
      if (diffPips < __config.minStopWidth) {
         sl = -1;
      }
   } else {
      sl = currentPrice.high;
      double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double diff = sl - bid;
      double diffPips = diff / unit;
      if (diffPips < __config.minStopWidth) {
         sl = -1;
      }
   }
   return sl;
}
