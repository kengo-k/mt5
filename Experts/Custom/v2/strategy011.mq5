#include <Custom/v2/Strategy/GridStrategy/01/StrategyTemplate.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>

// 以下固有ロジック提供するためのIF実装をincludeする
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CheckTrend/CheckTrendNoop.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/GetEntryCommand/GetEntryCommandWithoutTrend.mqh>

// 外部パラメータ
input double TP = 20;
input double TOTAL_HEDGE_TP = 200;
input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;
input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_D1;
input int ORDER_MA_PERIOD = 5;
input int ORDER_LONG_MA_PERIOD = 15;
input int HEDGE_MA_PERIOD = 5;
input int HEDGE_LONG_MA_PERIOD = 50;
input int ORDER_GRID_SIZE = 30;
input int HEDGE_GRID_SIZE = 15;

// 以下global変数に値を設定する
string EA_NAME = "strategy011";
bool USE_GRID_TRADE = true;
bool USE_GRID_HEDGE_TRADE = false;

Config __config__(
   TP
   , TOTAL_HEDGE_TP
   , CREATE_ORDER_TIMEFRAME
   , PERIOD_M1
   , HEDGE_DIRECTION_TIMEFRAME
   , ORDER_MA_PERIOD
   , ORDER_LONG_MA_PERIOD
   , HEDGE_MA_PERIOD
   , HEDGE_LONG_MA_PERIOD
   , ORDER_GRID_SIZE
   , HEDGE_GRID_SIZE
);
Config *__config = &__config__;

CheckTrend __checkTrend__;
ICheckTrend *__checkTrend = &__checkTrend__;

GetEntryCommand __getEntryCommand__;
IGetEntryCommand *__getEntryCommand = &__getEntryCommand__;