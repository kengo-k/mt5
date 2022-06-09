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
#import "MT5Lib.dll"

#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/VolumeCalculator.mqh>
#include <Custom/v2/Common/SpreadCalculator.mqh>
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

enum ENUM_ORDER_TIME_PARAM_SET {
   ORDER_TIME_PARAM_SET_M15_SHORT
};

enum ENUM_HEDGE_TIME_PARAM_SET {
   HEDGE_TIME_PARAM_SET_W1_MID
   , HEDGE_TIME_PARAM_SET_W1_LONG
   , HEDGE_TIME_PARAM_SET_MN1_SHORT
};

input group "利益・数量"

// 利益目標
input double TP = 20;

// ヘッジ決済目標利益学(要最適化)
input double TOTAL_HEDGE_TP = 1000;

input ENUM_VOLUME_SETTINGS VOLUME_SETTINGS = VOLUME_SETTINGS_MICRO_MIN;

input ENUM_SPREAD_SETTINGS SPREAD_SETTINGS = SPREAD_SETTINGS_NOOP; /* SPREAD_SETTINGS: 許容できる最大のスプレッド */

input group "トレード間隔"

// グリッドトレード用グリッドサイズ(要最適化)
input int ORDER_GRID_SIZE = 30;

// エントリ時間のパラメータセット
input ENUM_ORDER_TIME_PARAM_SET ORDER_TIME_PARAM_SET = ORDER_TIME_PARAM_SET_M15_SHORT;

// ヘッジ用グリッドサイズ(要最適化)
input int HEDGE_GRID_SIZE = 30;

// トレンド判定時間のパラメータセット
input ENUM_HEDGE_TIME_PARAM_SET HEDGE_TIME_PARAM_SET = HEDGE_TIME_PARAM_SET_W1_MID;

input group "トレード方式"

// 買/売を制限するかどうか
input ENUM_ENTRY_MODE ENTRY_MODE = ENTRY_MODE_BOTH;

// トレード方式(グリッドのみ/ヘッジのみ/両方)
input ENUM_TRADE_MODE TRADE_MODE = TRADE_MODE_GRID_AND_HEDGE;

// グリッドトレードのヘッジを行う場合の動作方式
input ENUM_GRID_HEDGE_MODE GRID_HEDGE_MODE = GRID_HEDGE_MODE_ONESIDE_CLOSE;

// 損益計算時にスワップを考慮に含めるかどうか
input ENUM_SWAP_INCLUDE SWAP_INCLUDE = SWAP_INCLUDE_OFF;

input group "その他"

input string TRADE_LOG_FILE = "trade_result"; /* TRADE_LOG_FILE: 取引履歴を記録するCSVファイル名を指定してください */

input string NOTIFY_CHANNEL = "gridstrategy1"; /* NOTIFY_CHANNEL: 通知するスラックのチャンネル名を指定してください */

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
         case VOLUME_SETTINGS_STANDARD_INCREASE:
            __volumeCalculator = new IncreaseVolumeCalculator(5000000, 0.01, 5000000, 0.01, 1);
            break;
         case VOLUME_SETTINGS_STANDARD_INCREASE_X2:
            __volumeCalculator = new IncreaseVolumeCalculator(5000000, 0.01, 5000000, 0.01, 2);
            break;
         case VOLUME_SETTINGS_STANDARD_INCREASE_X3:
            __volumeCalculator = new IncreaseVolumeCalculator(5000000, 0.01, 5000000, 0.01, 3);
            break;
         case VOLUME_SETTINGS_MICRO_MIN:
            __volumeCalculator = new FixedVolumeCalculator(0.1, 0.1);
            break;
         case VOLUME_SETTINGS_MICRO_INCREASE:
            __volumeCalculator = new IncreaseVolumeCalculator(500000, 0.1, 70000, 0.01, 2);
            break;
         case VOLUME_SETTINGS_MICRO_INCREASE_MID:
            //__volumeCalculator = new IncreaseVolumeCalculator(2000000, 4.0, 200000, 0.25, 1);
            __volumeCalculator = new IncreaseVolumeCalculator(2000000, 0.1, 200000, 0.25, 1);
            break;
         default:
            ExpertRemove();
      }

      TimeParamSet *orderTimeParamSet;
      switch(ORDER_TIME_PARAM_SET) {
         case ORDER_TIME_PARAM_SET_M15_SHORT:
            orderTimeParamSet = new TimeParamSet(PERIOD_M15, 5, 15);
            break;
         default:
            ExpertRemove();
      }

      TimeParamSet *hedgeTimeParamSet;
      switch(HEDGE_TIME_PARAM_SET) {
         case HEDGE_TIME_PARAM_SET_W1_MID:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_W1, 5, 20);
            break;
         case HEDGE_TIME_PARAM_SET_W1_LONG:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_W1, 5, 100);
            break;
         case HEDGE_TIME_PARAM_SET_MN1_SHORT:
            hedgeTimeParamSet = new TimeParamSet(PERIOD_MN1, 5, 15);
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
      } else if (SPREAD_SETTINGS == SPREAD_SETTINGS_USDJPY_STD) {
         spreadCalculator = new FixedSpreadCalculator(50);
      }
      int maxSpread = spreadCalculator.getMaxSpread();

      __config = new Config(
         TP
         , TOTAL_HEDGE_TP
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
      this.testResultRecorder = new TestResultRecorder(this.testResultFile);
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
      // ファイルは次のような場所に出力される C:\Users\$USERNAME\AppData\Roaming\MetaQuotes\Tester\$TERMINAL_ID\Agent-127.0.0.1-3000
      // $TERMINAL_IDは複数のMT5がインストールされている場合はそれぞれを識別するID
      // (MT5が利用できる複数の業者を利用する場合にMT5が複数インストールされる可能性がある)
      // セキュリティ上の理由から上記ディレクトリ以外の場所にファイルを出力することや読み込むことはできない模様
      this.testResultFile = FileOpen(
         StringFormat("%s\\%s",
            MT5Lib::DateUtil::GetCurrentDate(),
            Util::createUniqueFileName(TRADE_LOG_FILE, "csv")
         ), FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   }

   void closeFileHandles() {
      FileClose(this.testResultFile);
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

   int testResultFile;
   AccountObserver *accountObserver;
   TestResultRecorder *testResultRecorder;
   PositionObserver *allPositionObserver;
   PositionObserver *gridTradePositionObserver;
   PositionObserver *hedgeTradePositionObserver;
   HealthCheckNotifier *healthCheckNotifier;
};

Init *initializer = new Init();
