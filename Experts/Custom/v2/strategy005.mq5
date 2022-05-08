/**
 * グリッドトレードのバリエーション形
 * ・SL/TPは一切いれない
 * ・MAクロス後にグリッド価格でエントリする
 * ・合計利益が目標値を超えたら利益確定する。その後再度MAクロスが起こるまではエントリしない
 * ・目標値に到達する前にクロスが起きたらその時点ですべて手仕舞いする
 * ・メイン足: MAクロス判定(長期)、サブ足: エントリ(短期)
 *
 * FIXME: 時々ルールから外れた変なポジションが見受けられる・・・
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Common/GridManager.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy005";
const long MAGIC_NUMBER = 1;

input double VOLUME = 0.1;
input double TOTAL_TP = 300;
input ENUM_TIMEFRAMES SUB_TIMEFRAMES = PERIOD_M5;
input int MA_PERIOD = 5;
input int LONG_MA_PERIOD = 15;
input int GRID_SIZE = 10;

class Config {
public:
   // 取引量
   double volume;
   // 合計利益目標
   double totalTp;
   // 使用するMAの足
   ENUM_TIMEFRAMES subTimeFrames;
   // 長期MA期間
   int maPeriod;
   // 超長期MA期間
   int longMaPeriod;
   // グリッドの大きさ(pips)
   int gridSize;
   // 発注に使用する時間足
   ENUM_TIMEFRAMES orderPeriod;

   Config():
      volume(VOLUME)
      , totalTp(TOTAL_TP)
      , subTimeFrames(SUB_TIMEFRAMES)
      , maPeriod(MA_PERIOD)
      , longMaPeriod(LONG_MA_PERIOD)
      , gridSize(GRID_SIZE)
      , orderPeriod(PERIOD_M1) {}
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
RequestContainer __newOrderQueue;
RequestContainer __closeOrderQueue;
GridManager __gridManager(__config.gridSize);

Bar __createOrderBar(__config.subTimeFrames);
Bar __sendNewOrderBar(__config.orderPeriod);
Bar __sendCloseOrderBar(__config.orderPeriod);

ENUM_ENTRY_COMMAND __latestCommand = ENTRY_COMMAND_NOOP;

int OnInit() {
   __LOGGER__ = new Logger(EA_NAME);
   __context.maHandle = iMA(Symbol(), PERIOD_CURRENT, __config.maPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __sendCloseOrderBar.onBarCreated(sendCloseOrders);
   __createOrderBar.onBarCreated(createOrder);
   __sendNewOrderBar.onBarCreated(sendNewOrders);
}

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

double OnTester() {
   return Util::calcWinRatio();
}

bool __isProfitFixed = false;

/**
 * 現在の価格から次のグリッドの価格を算出し新規オーダーを生成しキューに追加する
 */
void createOrder() {

   CopyBuffer(__context.maHandle, 0, 0, 3, __context.ma);
   CopyBuffer(__context.longMaHandle, 0, 0, 3, __context.longMa);

   double latestMa = __context.ma[1];
   double latestLongMa = __context.longMa[1];
   double prevMa = __context.ma[0];
   double prevLongMa = __context.longMa[0];

   // MAのクロスが発生したら全決済
   if (
      (prevMa > prevLongMa && latestMa <= latestLongMa)
         || (prevMa <= prevLongMa && latestMa > latestLongMa)
   ) {
      addCloseAllPositionRequests();
      __isProfitFixed = false;
      return;
   }

   if (__isProfitFixed) {
      return;
   }

   // 目標利益に到達したら全決済
   double totalProfit = getTotalProfit();
   if (totalProfit >= __config.totalTp) {
      addCloseAllPositionRequests();
      __isProfitFixed = true;
      return;
   }

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (latestMa > latestLongMa) {
      command = ENTRY_COMMAND_BUY;
   } else {
      command = ENTRY_COMMAND_SELL;
   }

   // 次のグリッド価格を取得する
   double gridPrice = __gridManager.getTargetGridPrice(command);

   // 指値注文(TP付き)のリクエストを生成する
   Request* req = RequestContainer::createRequest();
   Order::createLimitRequest(command, req.item, gridPrice, __config.volume, -1, -1, MAGIC_NUMBER);

   // 長期間約定しない注文が残り続けないように一定期間で自動で削除されるようにする
   req.item.type_time = ORDER_TIME_SPECIFIED;
   req.item.expiration = Util::addSec(Util::addDay(Util::toDate(TimeCurrent()), 8), -1);

   // 注文をキューに入れる(後段の注文処理用の時間足で処理される ※00:00前後は市場がcloseしているため時間をずらしながらリトライする)
   __newOrderQueue.add(req);
}

/**
 * 生成したオーダーのキューからリクエストを送信する
 */
void sendNewOrders() {
   __gridManager.sendOrdersFromQueue(__newOrderQueue);
}

void addCloseAllPositionRequests() {
   int posCount = PositionsTotal();
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         Request* req = RequestContainer::createRequest();
         Order::createCloseRequest(req.item, posTicket, MAGIC_NUMBER);
         __closeOrderQueue.add(req);
      }
   }
}

void sendCloseOrders() {
   __gridManager.sendOrdersFromQueue(__closeOrderQueue, false);
}

double getTotalProfit() {
   double profit = 0;
   int posCount = PositionsTotal();
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         profit = profit + PositionGetDouble(POSITION_PROFIT);
      }
   }
   return profit;
}
