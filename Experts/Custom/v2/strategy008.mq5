/**
 * グリッドトレードのバリエーション形(007修正版)
 * ・001 + 007を同時に実行する
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy008";
const long MAGIC_NUMBER_MAIN = 1;
const long MAGIC_NUMBER_HEDGE = 2;

input ENUM_ENTRY_COMMAND ENTRY_COMMAND = ENTRY_COMMAND_NOOP;
input double VOLUME = 0.1;
input double TP = 20;
input double TOTAL_HEDGE_TP = 500;
input ENUM_TIMEFRAMES ADD_ORDER_PERIOD = PERIOD_M15;
input int MA_PERIOD = 5;
input int LONG_MA_PERIOD = 15;
input int GRID_SIZE = 30;

class Config {
public:
   ENUM_ENTRY_COMMAND entryCommand;
   // 取引量
   double volume;
   // 利益目標
   double tp;
   // ヘッジ利益目標
   double totalHedgeTp;
   // 注文生成に使用する時間足
   ENUM_TIMEFRAMES addOrderPeriod;
   // 長期MA期間
   int maPeriod;
   // 超長期MA期間
   int longMaPeriod;
   // グリッドの大きさ(pips)
   int gridSize;
   // 発注に使用する時間足
   ENUM_TIMEFRAMES sendOrderPeriod;

   Config():
      entryCommand(ENTRY_COMMAND)
      , volume(VOLUME)
      , tp(TP)
      , totalHedgeTp(TOTAL_HEDGE_TP)
      , addOrderPeriod(ADD_ORDER_PERIOD)
      , maPeriod(MA_PERIOD)
      , longMaPeriod(LONG_MA_PERIOD)
      , gridSize(GRID_SIZE)
      , sendOrderPeriod(PERIOD_M1) {}
};

class Context {
public:
   int maHandle;
   int longMaHandle;
   double ma[];
   double longMa[];
};

Config __config;
Context __context;


RequestContainer __newMainOrderQueue;
RequestContainer __newHedgeOrderQueue;
RequestContainer __closeOrderQueue;
RequestContainer __cancelOrderQueue;

GridManager __gridManager(__config.gridSize);

Bar __addOrderBar(__config.addOrderPeriod);
Bar __sendMainOrderBar(__config.sendOrderPeriod);
Bar __sendHedgeOrderBar(__config.sendOrderPeriod);
Bar __sendCloseOrderBar(__config.sendOrderPeriod);
Bar __sendCancelOrderBar(__config.sendOrderPeriod);
Bar __observeBar(PERIOD_D1);

int OnInit() {
   __LOGGER__ = new Logger(EA_NAME);
   __context.maHandle = iMA(Symbol(), PERIOD_CURRENT, __config.maPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __observeBar.onBarCreated(observe);
   __sendCloseOrderBar.onBarCreated(sendCloseOrders);
   __sendCancelOrderBar.onBarCreated(sendCancelOrders);
   __addOrderBar.onBarCreated(addOrderIntoQueue);
   __sendMainOrderBar.onBarCreated(sendMainOrders);
   __sendHedgeOrderBar.onBarCreated(sendHedgeOrders);
}

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

double OnTester() {
   return Util::calcWinRatio();
}

void observe() {
   int orderCount = OrdersTotal();
   int posCount = PositionsTotal();
   printf("★★★ [INFO] order count: %d, position count: %d", orderCount, posCount);
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規オーダーを生成しキューに追加する
 */
void addOrderIntoQueue() {

   CopyBuffer(__context.maHandle, 0, 0, 3, __context.ma);
   CopyBuffer(__context.longMaHandle, 0, 0, 3, __context.longMa);

   double latestMa = __context.ma[1];
   double latestLongMa = __context.longMa[1];
   double prevMa = __context.ma[0];
   double prevLongMa = __context.longMa[0];

   // 目標利益に到達したら全決済
   double hedgeProfit = calcTotalProfit(MAGIC_NUMBER_HEDGE, true, true);
   double mainProfit = calcTotalProfit(MAGIC_NUMBER_MAIN, true, false);
   if (hedgeProfit + mainProfit >= __config.totalHedgeTp) {
      addHedgePositionCloseOrders();
   }

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (latestMa > latestLongMa) {
      command = ENTRY_COMMAND_BUY;
   } else {
      command = ENTRY_COMMAND_SELL;
   }

   if (command != __config.entryCommand) {
      addAllPendingOrderCancelOrders();
   }

   // 次のグリッド価格を取得する
   double gridPrice = __gridManager.getTargetGridPrice(command);

   // 指値注文(TP付き)のリクエストを生成する
   Request* mainReq = RequestContainer::createRequest();
   Order::createLimitRequest(command, mainReq.item, gridPrice, __config.volume, -1, __config.tp, MAGIC_NUMBER_MAIN);
   __newMainOrderQueue.add(mainReq);

   // エントリ方向とトレンドが合致する場合のみエントリする
   if (command == __config.entryCommand) {
      // ヘッジ用指値注文(TP無し)のリクエストを生成する
      Request* hedgeReq = RequestContainer::createRequest();
      Order::createLimitRequest(command, hedgeReq.item, gridPrice, __config.volume, -1, -1, MAGIC_NUMBER_HEDGE);
      __newHedgeOrderQueue.add(hedgeReq);
   }
}


void sendMainOrders() {
   __gridManager.sendOrdersFromQueue(__newMainOrderQueue, MAGIC_NUMBER_MAIN);
}

void sendHedgeOrders() {
   __gridManager.sendOrdersFromQueue(__newHedgeOrderQueue, MAGIC_NUMBER_HEDGE);
}

// メインで損失が出ているポジションとヘッジ用ポジションの利益を相殺して決済する
void addHedgePositionCloseOrders() {
   int posCount = PositionsTotal();
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         long posMagicNumber = PositionGetInteger(POSITION_MAGIC);
         bool isAddRequired = false;
         if (posMagicNumber == MAGIC_NUMBER_HEDGE) {
            isAddRequired = true;
         }
         if (posMagicNumber == MAGIC_NUMBER_MAIN) {
            double profit = PositionGetDouble(POSITION_PROFIT);
            double swap = PositionGetDouble(POSITION_SWAP);
            if (profit + swap < 0) {
               isAddRequired = true;
            }
         }
         if (isAddRequired) {
            Request* req = RequestContainer::createRequest();
            Order::createCloseRequest(req.item, posTicket, posMagicNumber);
            __closeOrderQueue.add(req);
         }
      }
   }
}

void removeAllOrders(RequestContainer &queue) {
   int count = queue.count();
   for (int i = count -1; i >= 0; i--) {
      queue.remove(i);
   }
}

// 全指値注文をキャンセル
void addAllPendingOrderCancelOrders() {
   int orderCount = OrdersTotal();
   for (int i = 0; i < orderCount; i++) {
      ulong orderTicket = OrderGetTicket(i);
      if (orderTicket) {
         ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
         if (orderType == ORDER_TYPE_BUY_STOP
               || orderType == ORDER_TYPE_SELL_STOP) {
            Request* req = RequestContainer::createRequest();
            Order::createCancelRequest(req.item, orderTicket);
            __cancelOrderQueue.add(req);
         }
      }
   }
   removeAllOrders(__newMainOrderQueue);
   removeAllOrders(__newHedgeOrderQueue);
}


void sendCloseOrders() {
   __gridManager.sendOrdersFromQueue(__closeOrderQueue, -1);
}


void sendCancelOrders() {
   __gridManager.sendOrdersFromQueue(__cancelOrderQueue, -1);
}

double calcTotalProfit(long magicNumber, bool red = true, bool black = true) {
   double ret = 0;
   int posCount = PositionsTotal();
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         long posMagicNumber = PositionGetInteger(POSITION_MAGIC);
         if (magicNumber != posMagicNumber) {
            continue;
         }
         double profit = PositionGetDouble(POSITION_PROFIT);
         double swap = PositionGetDouble(POSITION_SWAP);
         double tmpRet = profit + swap;
         bool filter = false;
         if (red && tmpRet < 0) {
            filter = true;
         }
         if (black && tmpRet >= 0) {
            filter = true;
         }
         if (!filter) {
            continue;
         }
         ret = ret + tmpRet;
      }
   }
   return ret;
}
