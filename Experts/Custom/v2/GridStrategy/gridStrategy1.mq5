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

enum ENUM_ORDER_TIME_PARAM_SET {
   ORDER_TIME_PARAM_SET_M15_SHORT
};

enum ENUM_HEDGE_TIME_PARAM_SET {
   HEDGE_TIME_PARAM_SET_W1_MID
   , HEDGE_TIME_PARAM_SET_W1_LONG
   , HEDGE_TIME_PARAM_SET_MN1_SHORT
};

// 利益目標
input double TP = 20;

// ヘッジ決済目標利益学(要最適化)
input double TOTAL_HEDGE_TP = 1000;

// エントリ時間のパラメータセット
input ENUM_ORDER_TIME_PARAM_SET ORDER_TIME_PARAM_SET = ORDER_TIME_PARAM_SET_M15_SHORT;

// トレンド判定時間のパラメータセット
input ENUM_HEDGE_TIME_PARAM_SET HEDGE_TIME_PARAM_SET = HEDGE_TIME_PARAM_SET_W1_MID;

// エントリ時間足(たぶん固定)
//input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;

// エントリ判定短期MA期間(たぶん固定)
//input int ORDER_MA_PERIOD = 5;

// エントリ判定長期MA期間(たぶん固定)
//input int ORDER_LONG_MA_PERIOD = 15;

// トレンド判定時間足(たぶん固定)
//input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_W1;

// トレンド判定短期MA期間(最適化余地あり)
//input int HEDGE_MA_PERIOD = 5;

// トレンド判定短期MA期間(最適化余地あり)
//input int HEDGE_LONG_MA_PERIOD = 50;

// グリッドトレード用グリッドサイズ(要最適化)
input int ORDER_GRID_SIZE = 30;

// ヘッジ用グリッドサイズ(要最適化)
input int HEDGE_GRID_SIZE = 30;

// グリッドトレードを実行するかどうか
input bool USE_GRID_TRADE = true;

// グリッドトレードのヘッジを行うかどうか
input bool USE_GRID_HEDGE_TRADE = true;

// グリッドトレードのヘッジを行う場合の動作方式
input ENUM_GRID_HEDGE_MODE GRID_HEDGE_MODE = GRID_HEDGE_MODE_ONESIDE_CLOSE;

// 以下global変数に値を設定する
const string EA_NAME = "v2/Gridstrategy/gridStrategy1";
const Logger *__LOGGER__ = new Logger(EA_NAME, LOG_LEVEL_INFO);

// クローズタイミング
const ENUM_TIMEFRAMES CLOSE_TIMEFRAME = PERIOD_D1;

// 監視タイミング
const ENUM_TIMEFRAMES OBSERVE_TIMEFRAMES = PERIOD_MN1;

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

INIT_FN init = _init;
INIT_FN deInit = _deInit;
GET_CUSTOM_RESULT_FN getCustomResult = _getCustomResult;

Config *__config;
CheckTrend __checkTrend__;
ICheckTrend *__checkTrend = &__checkTrend__;

GetEntryCommand __getEntryCommand__;
IGetEntryCommand *__getEntryCommand = &__getEntryCommand__;

ClosePositions __closePositions__(CLOSE_TIMEFRAME);
IClosePositions *__closePositions = &__closePositions__;

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
      Print("NEKONEKONEKO");
      Print(HEDGE_TIME_PARAM_SET_W1_MID);
      Print(HEDGE_TIME_PARAM_SET_W1_LONG);
      Print(HEDGE_TIME_PARAM_SET_MN1_SHORT);
      this.initConfig();
      this.initLogSettings();
      this.openFileHandles();
      this.initObservers();
   }

   void deInit() {
      //this.logReport();
      this.deleteObservers();
      this.closeFileHandles();
      delete __config;
      delete __LOGGER__;
   }

private:

   void initConfig() {

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
            hedgeTimeParamSet = new TimeParamSet(PERIOD_W1, 5, 50);
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
         , USE_GRID_TRADE
         , USE_GRID_HEDGE_TRADE
         , GRID_HEDGE_MODE
      );

      delete orderTimeParamSet;
      delete hedgeTimeParamSet;
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

      // register observers
      //observerList.Add(this.accountObserver);
      observerList.Add(this.testResultRecorder);
      //observerList.Add(this.allPositionObserver);
      //observerList.Add(this.gridTradePositionObserver);
      //observerList.Add(this.hedgeTradePositionObserver);
   }

   void openFileHandles() {
      // ファイルは次のような場所に出力される C:\Users\$USERNAME\AppData\Roaming\MetaQuotes\Tester\$TERMINAL_ID\Agent-127.0.0.1-3000
      // $TERMINAL_IDは複数のMT5がインストールされている場合はそれぞれを識別するID
      // (MT5が利用できる複数の業者を利用する場合にMT5が複数インストールされる可能性がある)
      // セキュリティ上の理由から上記ディレクトリ以外の場所にファイルを出力することや読み込むことはできない模様
      this.testResultFile = FileOpen(Util::createUniqueFileName("test_result", "csv"), FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
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
};

Init *initializer = new Init();
