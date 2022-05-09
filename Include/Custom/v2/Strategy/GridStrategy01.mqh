/**
 * グリッドトレードのバリエーション形
 *
 * グリッドトレードでは必ず天井/大底をつかんでしまう(不可避)。そのため残高は増え続けていくが証拠金は減り続けて最終的には損失ポジションが積み重ねた利益を上回ってしまう。よって
 * ①天井/大底ポジション(クソポジ)を極力掴まないようにする
 * ②とはいえ必ず掴まされてしまうため極力数を減らしつつもつかんだ場合速やかに解消させるようにする
 * 以上の対策を行う。
 *
 * ①
 * 1:
 * ・基本方針としてはトレンド方向に合わせてエントリを行う
 * ・トレンド判定にはMAを使うのでトレンド途中は問題ないがトレンドの終わりにエントリしたポジションは必ずクソポジ化する
 * ・素直にMAのトレンド転換を待っていたのでは遅すぎる
 * ・よってトレンド転換の予兆を察知したらMA判定ではトレンド中でもエントリをしないようにする
 * ・トレンド転換の予兆は直近MA値がトレンドと逆行した場合とする(=MAのトレンド転換基準に到達する前(例えばMAクロスとか))
 *
 * 2:
 * ・トレンドの判定は実際にエントリを行う時間足よりも長い時間で見て判断する(かなりの長期で取るorひとつ(もしくはN個)上の時間足を使う)
 * ・エントリ可否判断は実際にエントリを行う時間足の判定と上記の(より長期の)トレンド判定が一致した場合とする
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Request.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/GridManager.mqh>

// 以下固有ロジック
#include <Custom/v2/Logic/011/Context.mqh>
// 設定値
#include <Custom/v2/Logic/011/Config.mqh>
// トレンド判定ロジックIF
#include <Custom/v2/Logic/011/ICheckTrend.mqh>
// エントリ判定ロジックIF
#include <Custom/v2/Logic/011/IGetEntryCommand.mqh>

Logger *__LOGGER__;

extern string EA_NAME;
extern bool USE_GRID_TRADE;
extern bool USE_GRID_HEDGE_TRADE;

extern Config *__config;
extern ICheckTrend *__checkTrend;
extern IGetEntryCommand *__getEntryCommand;

Context __context;

RequestContainer __newMainOrderQueue;
RequestContainer __newHedgeOrderQueue;
RequestContainer __closeOrderQueue;
RequestContainer __cancelOrderQueue;

GridManager __orderGrid;
GridManager __hedgeGrid;

Bar __createOrderBar;
Bar __sendMainOrderBar;
Bar __sendHedgeOrderBar;
Bar __sendCloseOrderBar;
Bar __sendCancelOrderBar;

int OnInit() {

   __LOGGER__ = new Logger(EA_NAME);
   __LOGGER__.setLogLevel(LOG_LEVEL_DEBUG);

   __context.orderMaHandle = iMA(Symbol(), __config.createOrderTimeframe, __config.orderMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.orderLongMaHandle = iMA(Symbol(), __config.createOrderTimeframe, __config.orderLongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.hedgeMaHandle = iMA(Symbol(), __config.hedgeDirectionTimeframe, __config.hedgeMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.hedgeLongMaHandle = iMA(Symbol(), __config.hedgeDirectionTimeframe, __config.hedgeLongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   __orderGrid.setGridSize(__config.orderGridSize);
   __hedgeGrid.setGridSize(__config.hedgeGridSize);
   
   __createOrderBar.setTimeframes(__config.createOrderTimeframe);
   __sendMainOrderBar.setTimeframes(__config.sendOrderTimeframe);
   __sendHedgeOrderBar.setTimeframes(__config.sendOrderTimeframe);
   __sendCloseOrderBar.setTimeframes(__config.sendOrderTimeframe);
   __sendCancelOrderBar.setTimeframes(__config.sendOrderTimeframe);

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
   ENUM_ENTRY_COMMAND hedgeDirection = __checkTrend.exec();
   ENUM_ENTRY_COMMAND command = __getEntryCommand.exec(hedgeDirection);

   logger.logDebug(StringFormat("command: %d", command));
   logger.logDebug(StringFormat("hedge direction: %d", hedgeDirection));

   if (USE_GRID_HEDGE_TRADE) {
      addHedgePositionCloseOrders();
      addAllPendingOrderCancelOrders();
   }

   if (command == ENTRY_COMMAND_NOOP) {
      return;
   }

   if (USE_GRID_TRADE) {
      double orderGridPrice = __orderGrid.getTargetGridPrice(command);
      Request* req = RequestContainer::createRequest();
      Order::createLimitRequest(command, req.item, orderGridPrice, getVolume(), -1, __config.tp, MAGIC_NUMBER_MAIN);
      __newMainOrderQueue.add(req);
   }

   if (USE_GRID_HEDGE_TRADE) {
      double hedgeGridPrice = __hedgeGrid.getTargetGridPrice(command);
      Request* hedgeReq = RequestContainer::createRequest();
      Order::createLimitRequest(command, hedgeReq.item, hedgeGridPrice, getVolume(), -1, -1, MAGIC_NUMBER_HEDGE);
      __newHedgeOrderQueue.add(hedgeReq);
   }
}

void addHedgePositionCloseOrders() {
   // TODO 後で
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
