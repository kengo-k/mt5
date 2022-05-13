 /**
 * グリッドトレードバリエーション
 *
 * 目的:
 * ・ヘッジロジックを単体で検証する
 *
 * 概要:
 * ・エントリ判定期間のMAとトレンド判定期間のMAで方向が一致した場合のみエントリする
 * ・指定した期間経過後に一定以上の黒字を持つポジションを決済する
 * ・赤字ポジションは解消できるまで持ち越す
 * ・最終的にトレンド転換の予兆もしくは転換で全て決済する
 *
 * 狙い:05ではトレンド転換の予兆までポジションを保持し続けたがその場合チャートの形が悪いと勝てないため、より早いタイミングで決済を目指してみる
 */
#include <Custom/v2/Strategy/GridStrategy/01/StrategyTemplate.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICloseHedgePositions.mqh>

// 以下固有ロジック提供するためのIF実装をincludeする
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CheckTrend/CheckTrend2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/GetEntryCommand/GetEntryCommand2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CloseHedgePositions/CloseHedgePositionsOnlyWhenEndOfTimeframe1.mqh>

// 決済目標利益学(たぶん固定。最適化してもよい)
input double TP = 10;

// エントリ時間足(たぶん固定)
input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;

// トレンド判定時間足(たぶん固定)
input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_MN1;

// エントリ判定短期MA期間(最適化余地あり)
input int ORDER_MA_PERIOD = 5;

// エントリ判定長期MA期間(最適化余地あり)
input int ORDER_LONG_MA_PERIOD = 15;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_MA_PERIOD = 5;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_LONG_MA_PERIOD = 15;

// ヘッジ用グリッドサイズ(たぶん固定。最適化してもよい)
input int HEDGE_GRID_SIZE = 10;

// クローズタイミング
input ENUM_TIMEFRAMES CLOSE_TIMEFRAME = PERIOD_MN1;

// 以下global変数に値を設定する
string EA_NAME = "gridstrategy01-06";
Logger *__LOGGER__ = new Logger(EA_NAME, LOG_LEVEL_INFO);
bool USE_GRID_TRADE = false;
bool USE_GRID_HEDGE_TRADE = true;

Config __config__(
   TP
   , -1//TOTAL_HEDGE_TP
   , CREATE_ORDER_TIMEFRAME
   , PERIOD_M1
   , HEDGE_DIRECTION_TIMEFRAME
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
