 /**
 * グリッドトレードバリエーション
 *
 * 目的:
 * ・グリッドトレードとヘッジトレードを組み合わせて運用する
 *
 * 概要:
 *
 * ・グリッドトレードで短期に利益を積み上げつつ発生した赤字ポジションをヘッジで決済する
 */
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/VolumeCalculator.mqh>
#include <Custom/v2/Common/SpreadCalculator.mqh>
#include <Custom/v2/Common/HedgeTpCalculator.mqh>
#include <Custom/v2/Strategy/GridStrategy/StrategyTemplate.mqh>
#include <Custom/v2/Strategy/GridStrategy/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/IGetEntryCommand.mqh>
#include <Custom/v2/Strategy/GridStrategy/IClosePositions.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

// 以下固有ロジック提供するためのIF実装をincludeする
#include <Custom/v2/Strategy/GridStrategy/Logic/CheckTrend/CheckTrend2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/GetEntryCommand/GetEntryCommand2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/ClosePositions/ClosePositions1.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/Observe.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/AccountObserver.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/PositionObserver.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/TestResultRecorder.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/HealthCheckNotifier.mqh>

input group "利益・数量"

input int TP = 20; /* TP: グリッドトレードの利益目標 */

input int HEDGE_TP = 10000; /* HEDGE_TP: ヘッジポジション決済時の合計利益目標を決定する際の基準値 */

input ENUM_HEDGE_TP_MODE HEDGE_TP_MODE = HEDGE_TP_MODE_FIXED; /* HEDGE_TP_MODE: ヘッジ決済額決定モード 0=固定値 1=増減あり(STD) 2=増減あり(MICRO) */

input ENUM_VOLUME_SETTINGS VOLUME_SETTINGS = VOLUME_SETTINGS_MICRO_MIN; /* VOLUME_SETTINGS: 数量 0-2=STD,※2=増減あり,3-5=MICRO,※5=増減あり */

input ENUM_SPREAD_SETTINGS SPREAD_SETTINGS = SPREAD_SETTINGS_NOOP; /* SPREAD_SETTINGS: 許容最大スプレッド 0=無制限,N-N+2(通貨別に厳しい,通常,緩め) */

input group "トレード間隔"

input int ORDER_GRID_SIZE = 30; /* ORDER_GRID_SIZE: グリッドトレード用グリッドサイズ */

// エントリ時間のパラメータセット
input ENUM_ORDER_TIME_PARAM_SET ORDER_TIME_PARAM_SET = ORDER_TIME_PARAM_SET_M15_SMALL; /* ORDER_TIME_PARAM_SET: グリッドトレード用トレード間隔 0-5=SMALL, 6-11=MIDDLE, 12-17=LONG */

// ヘッジ用グリッドサイズ(要最適化)
input int HEDGE_GRID_SIZE = 30; /* HEDGE_GRID_SIZE: ヘッジトレード用グリッドサイズ */

// トレンド判定時間のパラメータセット
input ENUM_HEDGE_TIME_PARAM_SET HEDGE_TIME_PARAM_SET = HEDGE_TIME_PARAM_SET_W1_MIDDLE; /* HEDGE_TIME_PARAM_SET: ヘッジトレード用トレード間隔 0-5=SMALL, 6-11=MIDDLE, 12-17=LONG */

input group "トレード方式"

// 買/売を制限するかどうか
input ENUM_ENTRY_MODE ENTRY_MODE = ENTRY_MODE_BOTH; /* ENTRY_MODE: エントリ方向の制限 0=買のみ 1=売のみ 2=両方*/

// トレード方式(グリッドのみ/ヘッジのみ/両方)
input ENUM_TRADE_MODE TRADE_MODE = TRADE_MODE_GRID_AND_HEDGE; /* TRADE_MODE: トレード方式  0=トレードなし 1=グリッドトレード 2=ヘッジトレード 3=両方 */

// グリッドトレードのヘッジを行う場合の動作方式
input ENUM_GRID_HEDGE_MODE GRID_HEDGE_MODE = GRID_HEDGE_MODE_ONESIDE_CLOSE; /* GRID_HEDGE_MODE: ヘッジポジション決済方式 0=決済なし 1=同方向のみで決済 2=両方向で決済 */

// 損益計算時にスワップを考慮に含めるかどうか
input ENUM_SWAP_INCLUDE SWAP_INCLUDE = SWAP_INCLUDE_OFF; /* SWAP_INCLUDE: 決済するかどうかの判定の利益計算にスワップを含めるかどうか 0=含めない 1=含める */

input group "その他"

input string NOTIFY_CHANNEL = "gridstrategy1"; /* NOTIFY_CHANNEL: 通知するスラックのチャンネル名を指定してください */

// パラメータ外の定数

const string TRADE_LOG_FILE = "trade_log"; /* TRADE_LOG_FILE: 取引履歴を記録するCSVファイル名を指定してください */

const string APP_LOG_FILE = "app"; /* APP_LOG_FILE: アプリケーションのログファイル名を指定してください */

// 以下global変数に値を設定する
const Logger *__LOGGER__ = new Logger(NOTIFY_CHANNEL, LOG_LEVEL_INFO);

// クローズタイミング
const ENUM_TIMEFRAMES CLOSE_TIMEFRAME = PERIOD_D1;

// 監視タイミング
const ENUM_TIMEFRAMES OBSERVE_TIMEFRAMES = PERIOD_H1;

void _init() {
   initializer.init();
}

void _deInit() {
   initializer.deInit();
   delete initializer;
}

double _getCustomResult() {
   // テスト中最もポジションを保有したときのポジション数
   //return (double) __allPositionObserver.maxTotalPositionCount;
   return 0;
}

// 初期化&終了処理
INIT_FN init = _init;
INIT_FN deInit = _deInit;
GET_CUSTOM_RESULT_FN getCustomResult = _getCustomResult;

Config *__config;

// トレンド判定ロジックIF&実装
CheckTrend __checkTrend__;
ICheckTrend *__checkTrend = &__checkTrend__;

// エントリ判定ロジックIF&実装
GetEntryCommand __getEntryCommand__;
IGetEntryCommand *__getEntryCommand = &__getEntryCommand__;

// 決済判定ロジック&実装
ClosePositions __closePositions__(CLOSE_TIMEFRAME);
IClosePositions *__closePositions = &__closePositions__;

// ボリューム計算ロジック&実装
IVolumeCalculator *__volumeCalculator;

// ヘッジTP計算ロジック&実装
IHedgeTpCalculator *__hedgeTpCalculator;

// 監視リスト
CArrayList<IObserver*> observerList;
Observe __observe__(&observerList);
IObserve *__observe = &__observe__;

class TimeParamSet {
public:
   TimeParamSet(ENUM_TIMEFRAMES _timeFrame, int _maPeriod, int _longMaPeriod):
      timeFrame(_timeFrame)
      , maPeriod(_maPeriod)
      , longMaPeriod(_longMaPeriod){};
   ENUM_TIMEFRAMES timeFrame;
   int maPeriod;
   int longMaPeriod;
};

// 初期化処理/終了処理を定義する
class Init {
public:

   void init() {
      this.initConfig();
      this.initLogSettings();
      this.openFileHandles();
      this.initObservers();
   }

   void deInit() {
      //this.logReport();
      this.deleteObservers();
      this.closeFileHandles();
      delete __volumeCalculator;
      delete __hedgeTpCalculator;
      delete __config;
      delete __LOGGER__;
   }

private:

   void initConfig() {
      // ボリュームの単位は業者(さらに言えば業者内でも口座のタイプによって)で変わる
      // XMの場合：
      // ・マイクロ口座
      //  1LOT = 1,000、最小ロット = 0.1LOT = 100通貨 ※MT5の場合。MT4の場合は0.01 = 10(のはず)
      // ・スタンダード口座
      //  1LOT = 100,000、最小ロット = 0.01LOT = 1000通貨

      switch(VOLUME_SETTINGS) {
         case VOLUME_SETTINGS_STANDARD_MIN:
            __volumeCalculator = new FixedVolumeCalculator(0.01, 0.01);
            break;
         case VOLUME_SETTINGS_STANDARD_SMALL:
            __volumeCalculator = new FixedVolumeCalculator(0.1, 0.1);
            break;
         case VOLUME_SETTINGS_STANDARD_INCREASE_SAFETY:
            __volumeCalculator = new IncreaseVolumeCalculator(50000000, 0.1, 5600000, 0.01, 1);
            break;
         case VOLUME_SETTINGS_MICRO_MIN:
            __volumeCalculator = new FixedVolumeCalculator(0.1, 0.1);
            break;
         case VOLUME_SETTINGS_MICRO_DEFAULT:
            __volumeCalculator = new FixedVolumeCalculator(1, 1);
            break;
         case VOLUME_SETTINGS_MICRO_INCREASE_SAFETY:
            __volumeCalculator = new IncreaseVolumeCalculator(300000, 0.1, 45000, 0.01, 1);
            break;
         default:
            ExpertRemove();
      }

      TimeParamSet *orderTimeParamSet;

      const int short_small = 5;
      const int long_small = 15;

      const int short_middle = 15;
      const int long_middle = 50;

      const int short_large = 15;
      const int long_large = 100;

      switch(ORDER_TIME_PARAM_SET) {
         case ORDER_TIME_PARAM_SET_M15_SMALL:
            orderTimeParamSet = new TimeParamSet(PERIOD_M15, short_small, long_small);
            break;
         case ORDER_TIME_PARAM_SET_H1_SMALL:
            orderTimeParamSet = new TimeParamSet(PERIOD_H1, short_small, long_small);
            break;
         case ORDER_TIME_PARAM_SET_H4_SMALL:
            orderTimeParamSet = new TimeParamSet(PERIOD_H4, short_small, long_small);
            break;
         case ORDER_TIME_PARAM_SET_D1_SMALL:
            orderTimeParamSet = new TimeParamSet(PERIOD_D1, short_small, long_small);
            break;
         case ORDER_TIME_PARAM_SET_W1_SMALL:
            orderTimeParamSet = new TimeParamSet(PERIOD_W1, short_small, long_small);
            break;
         case ORDER_TIME_PARAM_SET_MN1_SMALL:
            orderTimeParamSet = new TimeParamSet(PERIOD_MN1, short_small, long_small);
            break;

         case ORDER_TIME_PARAM_SET_M15_MIDDLE:
            orderTimeParamSet = new TimeParamSet(PERIOD_M15, short_middle, long_middle);
            break;
         case ORDER_TIME_PARAM_SET_H1_MIDDLE:
            orderTimeParamSet = new TimeParamSet(PERIOD_H1, short_middle, long_middle);
            break;
         case ORDER_TIME_PARAM_SET_H4_MIDDLE:
            orderTimeParamSet = new TimeParamSet(PERIOD_H4, short_middle, long_middle);
            break;
         case ORDER_TIME_PARAM_SET_D1_MIDDLE:
            orderTimeParamSet = new TimeParamSet(PERIOD_D1, short_middle, long_middle);
            break;
         case ORDER_TIME_PARAM_SET_W1_MIDDLE:
            orderTimeParamSet = new TimeParamSet(PERIOD_W1, short_middle, long_middle);
            break;
         case ORDER_TIME_PARAM_SET_MN1_MIDDLE:
            orderTimeParamSet = new TimeParamSet(PERIOD_MN1, short_middle, long_middle);
            break;

         case ORDER_TIME_PARAM_SET_M15_LARGE:
            orderTimeParamSet = new TimeParamSet(PERIOD_M15, short_large, long_large);
            break;
         case ORDER_TIME_PARAM_SET_H1_LARGE:
            orderTimeParamSet = new TimeParamSet(PERIOD_H1, short_large, long_large);
            break;
         case ORDER_TIME_PARAM_SET_H4_LARGE:
            orderTimeParamSet = new TimeParamSet(PERIOD_H4, short_large, long_large);
            break;
         case ORDER_TIME_PARAM_SET_D1_LARGE:
            orderTimeParamSet = new TimeParamSet(PERIOD_D1, short_large, long_large);
            break;
         case ORDER_TIME_PARAM_SET_W1_LARGE:
            orderTimeParamSet = new TimeParamSet(PERIOD_W1, short_large, long_large);
            break;
         case ORDER_TIME_PARAM_SET_MN1_LARGE:
            orderTimeParamSet = new TimeParamSet(PERIOD_MN1, short_large, long_large);
            break;
         default:
            ExpertRemove();
      }

      TimeParamSet *hedgeTimeParamSet;
      switch(HEDGE_TIME_PARAM_SET) {
         case HEDGE_TIME_PARAM_SET_M15_SMALL:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_M15, short_small, long_small);
            break;
         case HEDGE_TIME_PARAM_SET_H1_SMALL:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_H1, short_small, long_small);
            break;
         case HEDGE_TIME_PARAM_SET_H4_SMALL:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_H4, short_small, long_small);
            break;
         case HEDGE_TIME_PARAM_SET_D1_SMALL:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_D1, short_small, long_small);
            break;
         case HEDGE_TIME_PARAM_SET_W1_SMALL:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_W1, short_small, long_small);
            break;
         case HEDGE_TIME_PARAM_SET_MN1_SMALL:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_MN1, short_small, long_small);
            break;

         case HEDGE_TIME_PARAM_SET_M15_MIDDLE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_M15, short_middle, long_middle);
            break;
         case HEDGE_TIME_PARAM_SET_H1_MIDDLE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_H1, short_middle, long_middle);
            break;
         case HEDGE_TIME_PARAM_SET_H4_MIDDLE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_H4, short_middle, long_middle);
            break;
         case HEDGE_TIME_PARAM_SET_D1_MIDDLE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_D1, short_middle, long_middle);
            break;
         case HEDGE_TIME_PARAM_SET_W1_MIDDLE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_W1, short_middle, long_middle);
            break;
         case HEDGE_TIME_PARAM_SET_MN1_MIDDLE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_MN1, short_middle, long_middle);
            break;

         case HEDGE_TIME_PARAM_SET_M15_LARGE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_M15, short_large, long_large);
            break;
         case HEDGE_TIME_PARAM_SET_H1_LARGE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_H1, short_large, long_large);
            break;
         case HEDGE_TIME_PARAM_SET_H4_LARGE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_H4, short_large, long_large);
            break;
         case HEDGE_TIME_PARAM_SET_D1_LARGE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_D1, short_large, long_large);
            break;
         case HEDGE_TIME_PARAM_SET_W1_LARGE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_W1, short_large, long_large);
            break;
         case HEDGE_TIME_PARAM_SET_MN1_LARGE:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_MN1, short_large, long_large);
            break;
         default:
            ExpertRemove();
      }

      bool buyable = true;
      bool sellable = true;
      if (ENTRY_MODE == ENTRY_MODE_BUY_ONLY) {
         sellable = false;
      } else if (ENTRY_MODE == ENTRY_MODE_SELL_ONLY) {
         buyable = false;
      }

      bool useGridTrade = false;
      bool useGridHedegTrade = false;
      if (TRADE_MODE == TRADE_MODE_GRID_ONLY) {
         useGridTrade = true;
      } else if (TRADE_MODE == TRADE_MODE_HEDGE_ONLY) {
         useGridHedegTrade = true;
      } else if (TRADE_MODE == TRADE_MODE_GRID_AND_HEDGE) {
         useGridTrade = true;
         useGridHedegTrade = true;
      }

      bool isIncludeSwap = true;
      if (SWAP_INCLUDE == SWAP_INCLUDE_OFF) {
         isIncludeSwap = false;
      }

      ISpreadCalculator *spreadCalculator;
      if (SPREAD_SETTINGS == SPREAD_SETTINGS_NOOP) {
         spreadCalculator = new NoopSpreadCalculator();
      } else if (SPREAD_SETTINGS == SPREAD_SETTINGS_USDJPY_STRICT) {
         spreadCalculator = new FixedSpreadCalculator(35);
      } else if (SPREAD_SETTINGS == SPREAD_SETTINGS_USDJPY_DEFAULT) {
         spreadCalculator = new FixedSpreadCalculator(60);
      } else if (SPREAD_SETTINGS == SPREAD_SETTINGS_USDJPY_LAX) {
         spreadCalculator = new FixedSpreadCalculator(100);
      }
      int maxSpread = spreadCalculator.getMaxSpread();

      if (HEDGE_TP_MODE == HEDGE_TP_MODE_FIXED) {
         __hedgeTpCalculator = new FixedHedgeTpCalculator(HEDGE_TP);
      } else if (HEDGE_TP_MODE == HEDGE_TP_MODE_STANDARD_INCREASE) {
         __hedgeTpCalculator = new IncreaseHedgeTpCalculator(HEDGE_TP, 0.01);
      } else if (HEDGE_TP_MODE == HEDGE_TP_MODE_MICRO_INCREASE) {
         __hedgeTpCalculator = new IncreaseHedgeTpCalculator(HEDGE_TP, 0.1);
      }

      __config = new Config(
         TP
         , HEDGE_TP
         , HEDGE_TP_MODE
         , orderTimeParamSet.timeFrame
         , PERIOD_M1
         , hedgeTimeParamSet.timeFrame
         , OBSERVE_TIMEFRAMES
         , orderTimeParamSet.maPeriod
         , orderTimeParamSet.longMaPeriod
         , hedgeTimeParamSet.maPeriod
         , hedgeTimeParamSet.longMaPeriod
         , ORDER_GRID_SIZE
         , HEDGE_GRID_SIZE
         , useGridTrade
         , useGridHedegTrade
         , GRID_HEDGE_MODE
         , buyable
         , sellable
         , isIncludeSwap
         , VOLUME_SETTINGS
         , maxSpread
      );

      delete orderTimeParamSet;
      delete hedgeTimeParamSet;
      delete spreadCalculator;
   }

   void initLogSettings() {
      LOGID_POSITION.set(LOGID_STATE_ENABLED);
      //LOGID_POSITION_TOTAL.set(LOGID_STATE_ENABLED);
      //LOGID_ACCOUNT.set(LOGID_STATE_ENABLED);
      //LOGID_ACCOUNT_TOTAL.set(LOGID_STATE_ENABLED);
   }

   void initObservers() {
      // init observers
      this.accountObserver = new AccountObserver();
      this.testResultRecorder = new TestResultRecorder(this.tradeLogFile);
      this.allPositionObserver = new PositionObserver(0);
      this.gridTradePositionObserver = new PositionObserver(MAGIC_NUMBER_MAIN);
      this.hedgeTradePositionObserver = new PositionObserver(MAGIC_NUMBER_HEDGE);
      this.healthCheckNotifier = new HealthCheckNotifier();

      // register observers
      //observerList.Add(this.accountObserver);
      observerList.Add(this.testResultRecorder);
      //observerList.Add(this.allPositionObserver);
      //observerList.Add(this.gridTradePositionObserver);
      //observerList.Add(this.hedgeTradePositionObserver);
      //observerList.Add(this.healthCheckNotifier);
   }

   void openFileHandles() {
      bool isOptimize = MQLInfoInteger(MQL_OPTIMIZATION);
      if (isOptimize) {
         string prefix = "OptimizeResult";
         FolderDelete(prefix, FILE_COMMON);
         this.tradeLogFile = FileOpen(
            StringFormat("%s\\trade_log\\%s",
               prefix,
               Util::createUniqueFileName(TRADE_LOG_FILE, "csv")
            ), FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);

         this.appLogFile = FileOpen(
            StringFormat("%s\\app_log\\%s",
               prefix,
               Util::createUniqueFileName(APP_LOG_FILE, "log")
            ), FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
      } else {
         string prefix = "TestResult";
         FolderDelete(prefix, FILE_COMMON);
         this.tradeLogFile = FileOpen(
            StringFormat("%s\\trade_log\\%s.csv",
               prefix,
               TRADE_LOG_FILE
            ), FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);

         this.appLogFile = FileOpen(
            StringFormat("%s\\app_log\\%s.log",
               prefix,
               APP_LOG_FILE
            ), FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
      }
      __LOGGER__.setHandle(this.appLogFile);
   }

   void closeFileHandles() {
      FileClose(this.tradeLogFile);
      FileClose(this.appLogFile);
   }

   void deleteObservers() {
      delete this.accountObserver;
      delete this.testResultRecorder;
      delete this.allPositionObserver;
      delete this.gridTradePositionObserver;
      delete this.hedgeTradePositionObserver;
      delete this.healthCheckNotifier;
   }

   void logReport() {
      this.accountObserver.logTotalReport();
      this.gridTradePositionObserver.logTotalReport();
      this.hedgeTradePositionObserver.logTotalReport();
      this.allPositionObserver.logTotalReport();
   }

   int tradeLogFile;
   int appLogFile;
   AccountObserver *accountObserver;
   TestResultRecorder *testResultRecorder;
   PositionObserver *allPositionObserver;
   PositionObserver *gridTradePositionObserver;
   PositionObserver *hedgeTradePositionObserver;
   HealthCheckNotifier *healthCheckNotifier;
};

Init *initializer = new Init();
