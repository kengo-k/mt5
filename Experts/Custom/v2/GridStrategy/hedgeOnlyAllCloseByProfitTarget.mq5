 /**
 * グリッドトレードバリエーション
 *
 * 目的:
 * ・ヘッジロジックを単体で検証する
 *
 * 概要:
 * ・エントリ判定期間のMAとトレンド判定期間のMAで方向が一致した場合のみエントリする
 * ・指定した値以上の利益達成時にポジションを全て決済する
 * ・グリッドサイズはやや大きめ/利益目標値はかなり高めに設定して運用する
 *
 * 狙い:
 * ・目標値が低い場合すぐにポジションを決済してしまいヘッジが必要なタイミングで必要なポジションが足りなくなるため、かなり高めに設定する
 * ・グリッドサイズは小さすぎる場合ポジションが増えすぎて建玉上限にひっかかる/大きすぎる場合トレンド中に相殺できなくなるためやや大きめ程度の最適値を設定する
 * ・トレンド中は買い/売り双方とも中程度の赤字を抱え続けるがある程度ポジションを持ったあとは横ばいになる(その間にグリッドトレードで利益を上げるのが理想)
 * ・長期トレンド開始以降は買い/売りのバランスが崩れて利益が損失を大きく上回るタイミングが来るので溜め込んたポジションを一気に決済する
 */
 #include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Strategy/GridStrategy/StrategyTemplate.mqh>
#include <Custom/v2/Strategy/GridStrategy/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/IGetEntryCommand.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICloseHedgePositions.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

// 以下固有ロジック提供するためのIF実装をincludeする
#include <Custom/v2/Strategy/GridStrategy/Logic/CheckTrend/CheckTrend2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/GetEntryCommand/GetEntryCommand2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/CloseHedgePositions/CloseHedgePositionsOnlyWhenProfitAchievement.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/Observe.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/AccountObserver.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/PositionObserver.mqh>

// 決済目標利益学(たぶん固定。最適化してもよい)
input double TOTAL_HEDGE_TP = 50000;

// エントリ時間足(たぶん固定)
input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;

// トレンド判定時間足(たぶん固定)
input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_W1;

// エントリ判定短期MA期間(最適化余地あり)
input int ORDER_MA_PERIOD = 5;

// エントリ判定長期MA期間(最適化余地あり)
input int ORDER_LONG_MA_PERIOD = 15;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_MA_PERIOD = 5;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_LONG_MA_PERIOD = 50;

// ヘッジ用グリッドサイズ(たぶん固定。最適化してもよい)
input int HEDGE_GRID_SIZE = 30;

// 以下global変数に値を設定する
const string EA_NAME = "gridstrategy01-hedgeOnlyTargetProfitSetOff";
const Logger *__LOGGER__ = new Logger(EA_NAME, LOG_LEVEL_INFO);
const bool USE_GRID_TRADE = false;
const bool USE_GRID_HEDGE_TRADE = true;

// クローズタイミング
const ENUM_TIMEFRAMES CLOSE_TIMEFRAME = PERIOD_D1;

// 監視タイミング
const ENUM_TIMEFRAMES OBSERVE_TIMEFRAMES = PERIOD_D1;

void _init() {
   LOGID_ACCOUNT.set(LOGID_STATE_ENABLED);
   LOGID_POSITION.set(LOGID_STATE_ENABLED);
   LOGID_CLOSE.set(LOGID_STATE_ENABLED);
}

void _deInit() {
   __accountObserver.logTotalReport();
   __positionObserver.logTotalReport();
}

double _getCustomResult() {
   return 0;
}

INIT_FN init = _init;
INIT_FN deInit = _deInit;
GET_CUSTOM_RESULT_FN getCustomResult = _getCustomResult;

Config __config__(
   -1//TP
   , TOTAL_HEDGE_TP
   , CREATE_ORDER_TIMEFRAME
   , PERIOD_M1
   , HEDGE_DIRECTION_TIMEFRAME
   , OBSERVE_TIMEFRAMES
   , ORDER_MA_PERIOD
   , ORDER_LONG_MA_PERIOD
   , HEDGE_MA_PERIOD
   , HEDGE_LONG_MA_PERIOD
   , -1//ORDER_GRID_SIZE
   , HEDGE_GRID_SIZE
);
Config *__config = &__config__;

CheckTrend __checkTrend__;
ICheckTrend *__checkTrend = &__checkTrend__;

GetEntryCommand __getEntryCommand__;
IGetEntryCommand *__getEntryCommand = &__getEntryCommand__;

CloseHedgePositions __closeHedgePositions__(CLOSE_TIMEFRAME);
ICloseHedgePositions *__closeHedgePositions = &__closeHedgePositions__;

AccountObserver __accountObserver;
PositionObserver __positionObserver(MAGIC_NUMBER_HEDGE);
CArrayList<IObserver*> observerList;
CArrayList<IObserver*>* createObserverList() {
   observerList.Add(&__accountObserver);
   observerList.Add(&__positionObserver);
   return &observerList;
}
Observe __observe__(createObserverList());
IObserve *__observe = &__observe__;
