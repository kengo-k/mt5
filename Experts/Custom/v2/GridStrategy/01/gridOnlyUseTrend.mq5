 /**
 * グリッドトレードのみストラテジー(ヘッジなし)
 *
 * 目的:
 * ・トレンドを意識したグリッドストラテジーを試す
 *
 * 概要:
 * ・エントリ判定期間のMAとトレンド判定期間のMAで方向が一致した場合のみエントリする
 *
 * 狙い:
 * ・このストラテジーのみで勝つことはほぼ(というより確実に)不可能
 * ・どの程度の損失ポジションが生まれるのかを把握するための調査用として使う
 * ・あえてレンジ期間を選んで使用すれば比較的うまくいくはずということも確認したい　
 */
#include <Custom/v2/Strategy/GridStrategy/01/StrategyTemplate.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICloseHedgePositions.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IObserve.mqh>

// 以下固有ロジック提供するためのIF実装をincludeする
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CheckTrend/CheckTrend2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/GetEntryCommand/GetEntryCommand2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CloseHedgePositions/CloseHedgePositionsNoop.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/Observe/Observe.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/Observe/PositionObserver.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/Observe/AccountObserver.mqh>

// 外部パラメータ
input double TP = 30;
input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;
input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_W1;
input int ORDER_MA_PERIOD = 5;
input int ORDER_LONG_MA_PERIOD = 15;
input int HEDGE_MA_PERIOD = 5;
input int HEDGE_LONG_MA_PERIOD = 50;
input int ORDER_GRID_SIZE = 40;

// 以下global変数に値を設定する
const string EA_NAME = "gridstrategy01-gridOnlyUseTrend";
const Logger *__LOGGER__ = new Logger(EA_NAME, LOG_LEVEL_INFO);
const bool USE_GRID_TRADE = true;
const bool USE_GRID_HEDGE_TRADE = false;

const ENUM_TIMEFRAMES OBSERVE_TIMEFRAMES = PERIOD_D1;

void _init() {
   LOGID_POSITION_TOTAL.set(LOGID_STATE_ENABLED);
   LOGID_ACCOUNT_TOTAL.set(LOGID_STATE_ENABLED);
}

void _deInit() {
   __accountObserver.logTotalReport();
   __positionObserver.logTotalReport();
}

double _getCustomResult() {
   return __accountObserver.maxAccountBalance;
}

INIT_FN init = _init;
INIT_FN deInit = _deInit;
GET_CUSTOM_RESULT_FN getCustomResult = _getCustomResult;

Config __config__(
   TP
   , -1//TOTAL_HEDGE_TP
   , CREATE_ORDER_TIMEFRAME
   , PERIOD_M1
   , HEDGE_DIRECTION_TIMEFRAME
   , OBSERVE_TIMEFRAMES
   , ORDER_MA_PERIOD
   , ORDER_LONG_MA_PERIOD
   , HEDGE_MA_PERIOD
   , HEDGE_LONG_MA_PERIOD
   , ORDER_GRID_SIZE
   , -1//HEDGE_GRID_SIZE
);
Config *__config = &__config__;

CheckTrend __checkTrend__;
ICheckTrend *__checkTrend = &__checkTrend__;

GetEntryCommand __getEntryCommand__;
IGetEntryCommand *__getEntryCommand = &__getEntryCommand__;

CloseHedgePositions __closeHedgePositions__;
ICloseHedgePositions *__closeHedgePositions = &__closeHedgePositions__;

PositionObserver __positionObserver(MAGIC_NUMBER_MAIN);
AccountObserver __accountObserver;
CArrayList<IObserver*> observerList;
CArrayList<IObserver*>* createObserverList() {
   observerList.Add(&__positionObserver);
   observerList.Add(&__accountObserver);
   return &observerList;
}
Observe __observe__(createObserverList());
IObserve *__observe = &__observe__;
