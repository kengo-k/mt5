/**
 * グリッドトレードのバリエーション形(008修正版)
 * ・ヘッジする方向を固定ではなくトレンド判定により切り替える
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Common/GridManager.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy011";
const long MAGIC_NUMBER_MAIN = 1;
const long MAGIC_NUMBER_HEDGE = 2;

input double TP = 20;
input double TOTAL_HEDGE_TP = 200;
input ENUM_TIMEFRAMES CREATE_ORDER_PERIOD = PERIOD_H1;
input ENUM_TIMEFRAMES HEDGE_DIRECTION_PERIOD = PERIOD_D1;
input int ORDER_MA_PERIOD = 5;
input int ORDER_LONG_MA_PERIOD = 15;
input int HEDGE_MA_PERIOD = 5;
input int HEDGE_LONG_MA_PERIOD = 50;
input int ORDER_GRID_SIZE = 30;
input int HEDGE_GRID_SIZE = 15;

class Config {
public:
   double tp;
   double totalHedgeTp;
   ENUM_TIMEFRAMES createOrderPeriod;
   ENUM_TIMEFRAMES sendOrderPeriod;
   ENUM_TIMEFRAMES hedgeDirectionPeriod;
   int orderMaPeriod;
   int orderLongMaPeriod;
   int hedgeMaPeriod;
   int hedgeLongMaPeriod;
   int orderGridSize;
   int hedgeGridSize;

   Config():
      tp(TP)
      , totalHedgeTp(TOTAL_HEDGE_TP)
      , createOrderPeriod(CREATE_ORDER_PERIOD)
      , sendOrderPeriod(PERIOD_M1)
      , hedgeDirectionPeriod(HEDGE_DIRECTION_PERIOD)
      , orderMaPeriod(ORDER_MA_PERIOD)
      , orderLongMaPeriod(ORDER_LONG_MA_PERIOD)
      , hedgeMaPeriod(HEDGE_MA_PERIOD)
      , hedgeLongMaPeriod(HEDGE_LONG_MA_PERIOD)
      , orderGridSize(ORDER_GRID_SIZE)
      , hedgeGridSize(HEDGE_GRID_SIZE)
      {}
};

class Context {
public:
   int orderMaHandle;
   int orderLongMaHandle;
   int hedgeMaHandle;
   int hedgeLongMaHandle;
   double orderMa[];
   double orderLongMa[];
   double hedgeMa[];
   double hedgeLongMa[];
};

struct Summary {

   int totalCount;
   int buyCount;
   int sellCount;

   double total;
   double red;
   double black;

   double buy;
   double buyRed;
   double buyBlack;

   double sell;
   double sellRed;
   double sellBlack;
};

enum ENUM_HEDGE_MODE {
   HEDGE_MODE_MAIN
   , HEDGE_MODE_OPPOSITE
};

Config __config;
Context __context;

RequestContainer __newMainOrderQueue;
RequestContainer __newHedgeOrderQueue;
RequestContainer __closeOrderQueue;
RequestContainer __cancelOrderQueue;

GridManager __orderGrid(__config.orderGridSize);
GridManager __hedgeGrid(__config.hedgeGridSize);

Bar __createOrderBar(__config.createOrderPeriod);
Bar __sendMainOrderBar(__config.sendOrderPeriod);
Bar __sendHedgeOrderBar(__config.sendOrderPeriod);
Bar __sendCloseOrderBar(__config.sendOrderPeriod);
Bar __sendCancelOrderBar(__config.sendOrderPeriod);

ENUM_ENTRY_COMMAND __latestHedgeDirection = ENTRY_COMMAND_NOOP;
ENUM_HEDGE_MODE __hedgeMode = HEDGE_MODE_MAIN;

int OnInit() {
   __LOGGER__ = new Logger(EA_NAME);
   __LOGGER__.setLogLevel(LOG_LEVEL_INFO);
   __context.orderMaHandle = iMA(Symbol(), __config.createOrderPeriod, __config.orderMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.orderLongMaHandle = iMA(Symbol(), __config.createOrderPeriod, __config.orderLongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.hedgeMaHandle = iMA(Symbol(), __config.hedgeDirectionPeriod, __config.hedgeMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.hedgeLongMaHandle = iMA(Symbol(), __config.hedgeDirectionPeriod, __config.hedgeLongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __sendCloseOrderBar.onBarCreated(sendCloseOrders);
   __sendCancelOrderBar.onBarCreated(sendCancelOrders);
   __createOrderBar.onBarCreated(createOrder);
   __sendMainOrderBar.onBarCreated(sendMainOrders);
   __sendHedgeOrderBar.onBarCreated(sendHedgeOrders);
}

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

double getVolume() {
   return 0.1;
}

void createOrder() {
   LoggerFacade logger;

   ENUM_ENTRY_COMMAND command = getNextCommand();
   ENUM_ENTRY_COMMAND hedgeDirection = getHedgeDirection();

   // ヘッジ方向の切り替わりを検出
   if (__latestHedgeDirection != ENTRY_COMMAND_NOOP) {
      if (__latestHedgeDirection != hedgeDirection) {
         logger.logDebug("hedge direction switched!!!");
         __hedgeMode = HEDGE_MODE_OPPOSITE;
      }
   }
   __latestHedgeDirection = hedgeDirection;

   Summary mainSummary;
   Summary hedgeSummary;
   summaryPosition(mainSummary, MAGIC_NUMBER_MAIN);
   summaryPosition(hedgeSummary, MAGIC_NUMBER_HEDGE);

   logger.logDebug(StringFormat("command: %d", command), true);
   logger.logDebug(StringFormat("hedge direction: %d", hedgeDirection), true);

   addHedgePositionCloseOrders(mainSummary, hedgeSummary);

   if (command != hedgeDirection) {
      addAllPendingOrderCancelOrders();
   }

   double orderGridPrice = __orderGrid.getTargetGridPrice(command);
   Request* req = RequestContainer::createRequest();
   Order::createLimitRequest(command, req.item, orderGridPrice, getVolume(), -1, __config.tp, MAGIC_NUMBER_MAIN);
   //__newMainOrderQueue.add(req);

   if (command == hedgeDirection) {
      double hedgeGridPrice = __hedgeGrid.getTargetGridPrice(command);
      Request* hedgeReq = RequestContainer::createRequest();
      Order::createLimitRequest(command, hedgeReq.item, hedgeGridPrice, getVolume(), -1, -1, MAGIC_NUMBER_HEDGE);
      __newHedgeOrderQueue.add(hedgeReq);
   }
}

ENUM_ENTRY_COMMAND getNextCommand() {

   CopyBuffer(__context.orderMaHandle, 0, 0, 2, __context.orderMa);
   CopyBuffer(__context.orderLongMaHandle, 0, 0, 2, __context.orderLongMa);

   double latestMa = __context.orderMa[0];
   double latestLongMa = __context.orderLongMa[0];

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (latestMa > latestLongMa) {
      command = ENTRY_COMMAND_BUY;
   } else {
      command = ENTRY_COMMAND_SELL;
   }

   return command;
}

ENUM_ENTRY_COMMAND getHedgeDirection() {

   CopyBuffer(__context.hedgeMaHandle, 0, 0, 1, __context.hedgeMa);
   CopyBuffer(__context.hedgeLongMaHandle, 0, 0, 1, __context.hedgeLongMa);

   //double latestMa = __context.hedgeMa[0];
   double currentLongMa = __context.hedgeLongMa[0];

   MqlRates prices[];
   ArraySetAsSeries(prices, false);
   CopyRates(Symbol(), __config.createOrderPeriod, 0, 1, prices);
   MqlRates currentPrice = prices[0];

   ENUM_ENTRY_COMMAND direction = ENTRY_COMMAND_NOOP;
   //if (latestMa > latestLongMa) {
   //   direction = ENTRY_COMMAND_BUY;
   //} else {
   //   direction = ENTRY_COMMAND_SELL;
   //}
   if (currentPrice.close > currentLongMa) {
      direction = ENTRY_COMMAND_BUY;
   } else {
      direction = ENTRY_COMMAND_SELL;
   }

   return direction;
}

void addHedgePositionCloseOrders(Summary &mainSummary, Summary &hedgeSummary) {

   LoggerFacade logger;

   CArrayList<PosInfo*> closePosList;
   CArrayList<PosInfo*> buyHedgeList;
   CArrayList<PosInfo*> sellHedgeList;
   CArrayList<PosInfo*> buyMainList;
   CArrayList<PosInfo*> sellMainList;

   int posCount = PositionsTotal();
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         long posMagicNumber = PositionGetInteger(POSITION_MAGIC);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double swap = PositionGetDouble(POSITION_SWAP);
         PosInfo *p = new PosInfo();
         p.positionTicket = posTicket;
         p.profitAndSwap = profit + swap;
         p.swap = swap;
         p.magicNumber = posMagicNumber;
         if (posMagicNumber == MAGIC_NUMBER_MAIN && posType == POSITION_TYPE_BUY) {
            buyMainList.Add(p);
         } else if(posMagicNumber == MAGIC_NUMBER_MAIN && posType == POSITION_TYPE_SELL) {
            sellMainList.Add(p);
         } else if(posMagicNumber == MAGIC_NUMBER_HEDGE && posType == POSITION_TYPE_BUY) {
            buyHedgeList.Add(p);
         } else if(posMagicNumber == MAGIC_NUMBER_HEDGE && posType == POSITION_TYPE_SELL) {
            sellHedgeList.Add(p);
         }
      }
   }

   PosInfoComparer sortAsc(true);
   PosInfoComparer sortDesc(false);

   logger.logDebug(StringFormat("main position summary: buy(%d)=%f, sell(%d)=%f", mainSummary.buyCount, mainSummary.buy, mainSummary.sellCount, mainSummary.sell), true);
   logger.logDebug(StringFormat("hedge position summary: buy(%d)=%f, sell(%d)=%f", hedgeSummary.buyCount, hedgeSummary.buy, hedgeSummary.sellCount, hedgeSummary.sell), true);
   logger.logDebug(StringFormat("buy main: %s", Position::getPositionListString(&buyMainList)), true);
   logger.logDebug(StringFormat("sell main: %s", Position::getPositionListString(&sellMainList)), true);
   logger.logDebug(StringFormat("buy hedge: %s", Position::getPositionListString(&buyHedgeList)), true);
   logger.logDebug(StringFormat("sell hedge: %s", Position::getPositionListString(&sellHedgeList)), true);

   double hedgeSum = hedgeSummary.sell;
   double oppositeSum = 0;
   CArrayList<PosInfo*> *hedgeList = &sellHedgeList;
   CArrayList<PosInfo*> *oppositeList = &buyHedgeList;
   if (__latestHedgeDirection == ENTRY_COMMAND_BUY) {
      hedgeSum = hedgeSummary.buy;
      hedgeList = &buyHedgeList;
      oppositeList = &sellHedgeList;
      oppositeList.Sort(&sortDesc);
   }

   int oCount = oppositeList.Count();
   for (int i = 0; i < oCount; i++) {
      PosInfo *p;
      oppositeList.TryGetValue(i, p);
      oppositeSum += p.profitAndSwap;
      if (hedgeSum + oppositeSum < __config.totalHedgeTp) {
         break;
      }
      closePosList.Add(p);
   }

   if (closePosList.Count() > 0) {
      int hCount = hedgeList.Count();
      for (int i = 0; i < hCount; i++) {
         PosInfo *p;
         hedgeList.TryGetValue(i, p);
         closePosList.Add(p);
      }
   }

   int cCount = closePosList.Count();
   for (int i = 0; i < cCount; i++) {
      PosInfo *p;
      closePosList.TryGetValue(i, p);
      logger.logDebug(StringFormat("add position #%d in close position list", p.positionTicket), true);
      Request* req = RequestContainer::createRequest();
      Order::createCloseRequest(req.item, p.positionTicket, p.magicNumber);
      __closeOrderQueue.add(req);
   }

   Position::deletePositionList(&buyHedgeList);
   Position::deletePositionList(&sellHedgeList);
   Position::deletePositionList(&buyMainList);
   Position::deletePositionList(&sellMainList);
}

void sendMainOrders() {
   __orderGrid.sendOrdersFromQueue(__newMainOrderQueue, MAGIC_NUMBER_MAIN);
}

void sendHedgeOrders() {
   __orderGrid.sendOrdersFromQueue(__newHedgeOrderQueue, MAGIC_NUMBER_HEDGE);
}

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

void removeAllOrders(RequestContainer &queue) {
   int count = queue.count();
   for (int i = count -1; i >= 0; i--) {
      queue.remove(i);
   }
}

void sendCloseOrders() {
   __orderGrid.sendOrdersFromQueue(__closeOrderQueue, -1);
}


void sendCancelOrders() {
   __orderGrid.sendOrdersFromQueue(__cancelOrderQueue, -1);
}

void summaryPosition(Summary &summary, long magicNumber) {

   int buyCount = 0;
   int sellCount = 0;

   double red = 0;
   double black = 0;
   double buy = 0;
   double buyRed = 0;
   double buyBlack = 0;

   double sell = 0;
   double sellRed = 0;
   double sellBlack = 0;

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
         double profitAndSwap = profit + swap;
         if (profitAndSwap < 0) {
            red = red + profitAndSwap;
         } else {
            black = black + profitAndSwap;
         }
         ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         if (positionType == POSITION_TYPE_BUY) {
            if (profitAndSwap < 0) {
               buyRed = buyRed + profitAndSwap;
            } else {
               buyBlack = buyBlack + profitAndSwap;
            }
            buy = buy + profitAndSwap;
            buyCount++;
         } else {
            if (profitAndSwap < 0) {
               sellRed = sellRed + profitAndSwap;
            } else {
               sellBlack = sellBlack + profitAndSwap;
            }
            sell = sell + profitAndSwap;
            sellCount++;
         }
      }
   }

   summary.totalCount = buyCount + sellCount;
   summary.buyCount = buyCount;
   summary.sellCount = sellCount;

   summary.total = buy + sell;
   summary.red = red;
   summary.black = black;

   summary.buy = buy;
   summary.buyRed = buyRed;
   summary.buyBlack = buyBlack;

   summary.sell = sell;
   summary.sellRed = sellRed;
   summary.sellBlack = sellBlack;
}
