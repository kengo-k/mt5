/**
 * グリッドトレードのバリエーション形
 * 一定期間で損切り + トレールで利益を伸ばし損切り分の相殺を目指す
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Bar.mqh>
#include <Custom/v2/Logic/RequestContainer.mqh>
#include <Custom/v2/Logic/Grid/GridManager.mqh>

const string EA_NAME = "strategy007";
const long MAGIC_NUMBER = 1;
input double VOLUME = 0.1;
input int LONG_MA_PERIOD = 5;
input int LONG_LONG_MA_PERIOD = 15;
input int GRID_SIZE = 10;
input int STOP_DAY = 30;
input int TP_SIZE = 10;
input int TP_TARGET = 20;

class Config {
public:
   
   // 取引量
   double volume;
   int tpSize;
   int tpTarget;
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
   // グリッドの大きさ(pips)
   int gridSize;
   // 発注に使用する時間足
   ENUM_TIMEFRAMES orderPeriod;
   
   Config():
      volume(VOLUME)
      , tpSize(TP_SIZE)
      , tpTarget(TP_TARGET)
      , longMaPeriod(LONG_MA_PERIOD)
      , longlongMaPeriod(LONG_LONG_MA_PERIOD)
      , gridSize(GRID_SIZE)
      , orderPeriod(PERIOD_M1) {}
};

class Context {
public:
   int longMaHandle;
   int longlongMaHandle;
   double longMA[];
   double longlongMA[];
};


Logger logger(EA_NAME);
Config __config;
Context __context;
GridManager __gridManager(__config.gridSize);

// 新規注文キュー
RequestContainer __newOrderQueue;
// 更新注文キュー
RequestContainer __updateOrderQueue;
// ストップ注文キュー
RequestContainer __stopOrderQueue;
// 新規注文の生成を判断するための足
Bar __createNewOrderBar(PERIOD_CURRENT);
Bar __updateOrderBar(PERIOD_M1);
// 新規注文キューを処理するための足
Bar __sendNewOrderBar(PERIOD_M5);
// ストップ注文の生成を判断するための足
Bar __createStopOrderBar(PERIOD_D1);
Bar __sendUpdateOrderBar(PERIOD_M1);
// ストップ注文キューを処理するための足
Bar __sendStopOrderBar(PERIOD_M5);


int OnInit() {
   __context.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   __context.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, __config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   __updateOrderBar.onBarCreated(updateOrder);
   // ストップ注文キューを随時処理する
   __sendStopOrderBar.onBarCreated(sendStopOrder);
   // 保持しているポジションが一定期間を過ぎたら強制決済する
   __createStopOrderBar.onBarCreated(createStopOrder);
   // 指定価格に到達したら指値注文を注文キューに追加する
   __createNewOrderBar.onBarCreated(createNewOrder);
   // 新規注文キューを随時処理する
   __sendNewOrderBar.onBarCreated(sendNewOrder);
}

/**
 * 現在の価格から次のグリッドの価格を算出し新規注文のリクエストを生成しキューに追加する
 */
void createNewOrder() {

   CopyBuffer(__context.longMaHandle, 0, 0, 2, __context.longMA);
   CopyBuffer(__context.longlongMaHandle, 0, 0, 2, __context.longlongMA);

   double longMa = __context.longMA[0];
   double longlongMa = __context.longlongMA[0];

   ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
   if (longMa > longlongMa) {
      command = ENTRY_COMMAND_BUY;
   } else {
      command = ENTRY_COMMAND_SELL;
   }

   // 次のグリッド価格を取得する
   double gridPrice = __gridManager.getTargetGridPrice(command);
   Request* req = __newOrderQueue.createRequest();
   // 指値注文(TP付き)のリクエストを生成する
   Order::createLimitRequest(command, req.item, gridPrice, __config.volume, -1, -1, MAGIC_NUMBER);   
   // 長期間約定しない注文が残り続けないように一定期間で自動で削除されるようにする
   req.item.type_time = ORDER_TIME_SPECIFIED;
   req.item.expiration = Util::addSec(Util::addDay(Util::toDate(TimeCurrent()), 8), -1);
   // 注文をキューに入れる(注文処理用の時間足で処理される ※00:00前後は市場がcloseしているため時間をずらしながらリトライする)
   __newOrderQueue.add(req);
}

/**
 * 利益を確定できる状態になったらSLを設定する
 */
void updateOrder() {
   double unit = Util::getUnit();
   int posCount = PositionsTotal();
   MqlTradeResult result;
   for (int i = 0; i < posCount; i++) {
      ulong posTicket = PositionGetTicket(i);
      if (posTicket) {
         double sl = PositionGetDouble(POSITION_SL);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         double newSL = -1;
         double basePrice = PositionGetDouble(POSITION_PRICE_OPEN);
         if (sl > 0) {
            basePrice = sl;
         }
         if (type == POSITION_TYPE_BUY) {
            double profit = (currentPrice - basePrice) / unit;
            if (profit > __config.tpTarget) {
               newSL = basePrice + (__config.tpSize * unit);
            }
         } else {
            double profit = (basePrice - currentPrice) / unit;
            if (profit > __config.tpTarget) {
               newSL = basePrice - (__config.tpSize * unit);
            }               
         }
         if (newSL > 0) {
            Request *req = __updateOrderQueue.createRequest();
            Order::createSlTpRequest(req.item, newSL, -1, MAGIC_NUMBER);
            ZeroMemory(result);
            logger.logRequest(req.item);
            bool isSended = OrderSend(req.item, result);
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
         }
      }
   }
}

/**
 * 新規注文キューを処理して新規注文リクエストを送信する
 */
void sendNewOrder() {
   MqlTradeResult result;
   int orderCount = __newOrderQueue.count();
   for (int i = orderCount - 1; i >= 0; i--) {
      // キューからリクエストを取得する
      Request *req = __newOrderQueue.get(i);
      double price = req.item.price;
      ENUM_ORDER_TYPE type = req.item.type;
      // リクエストの価格がすでに使われている場合(買い/売りそれぞれ同時に一つまで)は
      // キューから削除し発注せずに終了する
      if (__gridManager.isGridPriceUsed(type, price)) {
         __newOrderQueue.remove(i);
         continue;
      }
      // 発注処理
      ZeroMemory(result);
      logger.logRequest(req.item);
      bool isSended = OrderSend(req.item, result);
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

      __newOrderQueue.remove(i);
   }
}

/**
 * 一定期間以上保持しているポジションが存在する場合、
 * 損失を確定させるために損切り注文のリクエストをキューに送信する
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
         if (diffDay > STOP_DAY && profit < 0) {
            Request* req = __stopOrderQueue.createRequest();
            Order::createCloseRequest(req.item, posTicket, MAGIC_NUMBER);
            __stopOrderQueue.add(req);
         }
      }
   }
}

/**
 * 損切り注文キューを処理して新規注文リクエストを送信する
 */
void sendStopOrder() {
   MqlTradeResult result;
   int orderCount = __stopOrderQueue.count();
   for (int i = orderCount - 1; i >= 0; i--) {
      // キューからリクエストを取得する
      Request *req = __stopOrderQueue.get(i);
      // 発注処理
      ZeroMemory(result);
      logger.logRequest(req.item);
      bool isSended = OrderSend(req.item, result);
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
      // 想定外のエラーのため念のためシステム停止
      if (!isValid) {
         ExpertRemove();
      }

      __stopOrderQueue.remove(i);
   }
}
