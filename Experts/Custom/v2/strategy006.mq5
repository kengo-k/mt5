/**
 * グリッドトレードのバリエーション形
 * 損失の膨らんだポジションを一定期間経過後に損切りする
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy006";
const long MAGIC_NUMBER = 1;

input double VOLUME = 0.1;
input double TP = 25;
input int MA_PERIOD = 5;
input int LONG_MA_PERIOD = 15;
input int GRID_SIZE = 10;
input int STOP_DAY = 30;
input double STOP_THRESHOLD = 100;

class Config {
public:
   // 取引量
   double volume;
   // 利益目標(pips)
   double tp;
   // 長期MA期間
   int maPeriod;
   // 超長期MA期間
   int longMaPeriod;
   // グリッドの大きさ(pips)
   int gridSize;
   // ポジションを保持してからこの値以上の期間が経過したものを損切りするという日数
   int stopDay;
   // stopDay以上の日数が経過したポジションでこの値以上の損失がでたものを損切りするという値(pips)
   double stopThreshold;
   // 発注に使用する時間足
   ENUM_TIMEFRAMES orderPeriod;

   Config():
      volume(VOLUME)
      , tp(TP)
      , maPeriod(MA_PERIOD)
      , longMaPeriod(LONG_MA_PERIOD)
      , gridSize(GRID_SIZE)
      , stopDay(STOP_DAY)
      , stopThreshold(STOP_THRESHOLD)
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
GridManager __gridManager(__config.gridSize);

// 新規注文キュー
RequestContainer __newOrderQueue;
// ストップ注文キュー
RequestContainer __stopOrderQueue;

// 新規注文の生成を判断するための足
Bar __createNewOrderBar(PERIOD_CURRENT);
// 新規注文キューを処理するための足
Bar __sendNewOrderBar(PERIOD_M1);
// ストップ注文の生成を判断するための足
Bar __createStopOrderBar(PERIOD_D1);
// ストップ注文キューを処理するための足
Bar __sendStopOrderBar(PERIOD_M1);


int OnInit() {
   __LOGGER__ = new Logger(EA_NAME);
   __context.maHandle = iMA(Symbol(), PERIOD_CURRENT, __config.maPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
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

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規注文のリクエストを生成しキューに追加する
 */
void createNewOrder() {

   CopyBuffer(__context.maHandle, 0, 0, 2, __context.ma);
   CopyBuffer(__context.longMaHandle, 0, 0, 2, __context.longMa);

   double ma = __context.ma[0];
   double longMa = __context.longMa[0];

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (ma > longMa) {
      command = ENTRY_COMMAND_BUY;
   } else {
      command = ENTRY_COMMAND_SELL;
   }

   double gridPrice = __gridManager.getTargetGridPrice(command);

   Request* req = RequestContainer::createRequest();
   Order::createLimitRequest(command, req.item, gridPrice, __config.volume, -1, __config.tp, MAGIC_NUMBER);

   req.item.type_time = ORDER_TIME_SPECIFIED;
   req.item.expiration = Util::addSec(Util::addDay(Util::toDate(TimeCurrent()), 8), -1);

   __newOrderQueue.add(req);
}

/**
 * 新規注文キューを処理して新規注文リクエストを送信する
 */
void sendNewOrder() {
   __gridManager.sendOrdersFromQueue(__newOrderQueue);
}

/**
 * 一定期間以上保持＆一定額以上の損失が出ているポジションが存在する場合損切り注文のリクエストをキューに送信する
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
         // ポジション保持期間が閾値以上で利益が出ていないポジションは場合は損切り用のキューにリクエストを追加
         if (diffDay > __config.stopDay && profit < __config.stopThreshold) {
            Request* req = __stopOrderQueue.createRequest();
            Order::createCloseRequest(req.item, posTicket, MAGIC_NUMBER);
            __stopOrderQueue.add(req);
         }
      }
   }
}

/**
 * 損切り注文キューを処理してリクエストを送信する
 */
void sendStopOrder() {
   __gridManager.sendOrdersFromQueue(__stopOrderQueue, false);
}