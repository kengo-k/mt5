/**
 * グリッドトレードの
 * 損切り等一切無しのシンプルストラテジー
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>

Logger *__LOGGER__;

const string EA_NAME = "strategy005";
const long MAGIC_NUMBER = 1;

input double VOLUME = 0.1;
input double TP = 25;
input int MA_PERIOD = 5;
input int LONG_MA_PERIOD = 15;
input int GRID_SIZE = 10;

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
   // 発注に使用する時間足
   ENUM_TIMEFRAMES orderPeriod;

   Config():
      volume(VOLUME)
      , tp(TP)
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
RequestContainer __orderQueue;
GridManager __gridManager(__config.gridSize);

Bar __mainBar(PERIOD_CURRENT);
Bar __orderBar(__config.orderPeriod);

int OnInit() {
   __LOGGER__ = new Logger(EA_NAME);
   __context.maHandle = iMA(Symbol(), PERIOD_CURRENT, __config.maPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __mainBar.onBarCreated(createOrder);
   __orderBar.onBarCreated(sendOrders);
}

void OnDeinit(const int reason) {
   delete __LOGGER__;
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規オーダーを生成しキューに追加する
 */
void createOrder() {

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

   // 次のグリッド価格を取得する
   double gridPrice = __gridManager.getTargetGridPrice(command);

   // 指値注文(TP付き)のリクエストを生成する
   Request* req = RequestContainer::createRequest();
   Order::createLimitRequest(command, req.item, gridPrice, __config.volume, -1, __config.tp, MAGIC_NUMBER);

   // 長期間約定しない注文が残り続けないように一定期間で自動で削除されるようにする
   req.item.type_time = ORDER_TIME_SPECIFIED;
   req.item.expiration = Util::addSec(Util::addDay(Util::toDate(TimeCurrent()), 8), -1);

   // 注文をキューに入れる(後段の注文処理用の時間足で処理される ※00:00前後は市場がcloseしているため時間をずらしながらリトライする)
   __orderQueue.add(req);
}

/**
 * 生成したオーダーのキューからリクエストを送信する
 */
void sendOrders() {
   __gridManager.sendOrdersFromQueue(__orderQueue);
}
