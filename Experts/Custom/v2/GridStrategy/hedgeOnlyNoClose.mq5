 /**
 * グリッドトレード用ヘッジロジック調査用ストラテジー
 *
 * 目的:
 * ・エントリーのみを行いポジションを溜め込み続けることで利益と損失のバランスがどのように変化するかを検証する
 *
 * 概要:
 * ・エントリ判定期間のMAとトレンド判定期間のMAで方向が一致した場合のみエントリする
 * ・調査用なので決済は一切しない
 *
 * 狙い:
 * ・最終的にグリッドトレードの赤字分(および自身の赤字分)を相殺することを目指すためかなり高めの利益を目指す必要があり
 * 　トータル利益目標をどれくらいに設定するべきかを検討するデータを取得する。
 * ・(業者によって建玉上限があるため)合計ポジション数にも注意する。ひとまず200ポジションを以下を維持できるかどうかを検証する
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
#include <Custom/v2/Strategy/GridStrategy/Logic/CloseHedgePositions/CloseHedgePositionsNoop.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/Observe.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/Observe/PositionObserver.mqh>

// エントリ時間足(たぶん固定)
input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;

// トレンド判定時間足(最適化余地あり)
input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_W1;

// エントリ判定短期MA期間(多分固定)
input int ORDER_MA_PERIOD = 5;

// エントリ判定長期MA期間(多分固定)
input int ORDER_LONG_MA_PERIOD = 15;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_MA_PERIOD = 5;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_LONG_MA_PERIOD = 15;

// ヘッジ用グリッドサイズ(要最適化対象)
input int HEDGE_GRID_SIZE = 30;

// 以下global変数に値を設定する
const string EA_NAME = "gridstrategy01-hedgeEntryOnly";
const Logger *__LOGGER__ = new Logger(EA_NAME, LOG_LEVEL_INFO);
const bool USE_GRID_TRADE = false;
const bool USE_GRID_HEDGE_TRADE = true;

const ENUM_TIMEFRAMES OBSERVE_TIMEFRAMES = PERIOD_D1;

void _init() {
   LOGID_POSITION.set(LOGID_STATE_ENABLED);
}

void _deInit() {
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
   , -1//TOTAL_HEDGE_TP
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

CloseHedgePositions __closeHedgePositions__;
ICloseHedgePositions *__closeHedgePositions = &__closeHedgePositions__;

PositionObserver __positionObserver(MAGIC_NUMBER_HEDGE);
CArrayList<IObserver*> observerList;
CArrayList<IObserver*>* createObserverList() {
   observerList.Add(&__positionObserver);
   return &observerList;
}
Observe __observe__(createObserverList());
IObserve *__observe = &__observe__;
