/**
 * エントリ:
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Context/Context001.mqh>
#include <Custom/v2/Context/ContextHelper.mqh>
#include <Custom/v2/Builder/StrategyBuilder001.mqh>
#include <Custom/v2/Logic/Open/Open001.mqh>

const string EA_NAME = "strategy001";
const long MAGIC_NUMBER = 1;
input double SL = 4;
input double TP = 8;
input double VOLUME = 0.1;
input int SHORT_MA_PERIOD = 5;
input int LONG_MA_PERIOD = 100;
input int LONG_LONG_MA_PERIOD = 200;
input int MACD_PERIOD1 = 12;
input int MACD_PERIOD2 = 26;
input int MACD_PERIOD3 = 9;

Config001 __config = Config001Factory::create(
   EA_NAME
   , MAGIC_NUMBER
   , SL
   , TP
   , VOLUME
   , SHORT_MA_PERIOD
   , LONG_MA_PERIOD
   , LONG_LONG_MA_PERIOD
   , MACD_PERIOD1
   , MACD_PERIOD2
   , MACD_PERIOD3
);

void initContext(Context001 &main, Context001 &sub, Config001 &config) {
   ContextHelper::initContext(main, sub, config);
}

void open(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
   Open001::open(contextMain, contextSub, config);
}

void close(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
}

StrategyBuilder001<Config001, Context001> st(
   __config
   , initContext
   , open
   , close
   , EA_NAME
   , MAGIC_NUMBER
);

int OnInit() {
   Logger logger(__config.eaName);
   string symbol = Symbol();
   string period = Util::getPeriodName(Period());
   double unit = Util::getUnit();
   logger.logWrite(LOG_LEVEL_INFO, StringFormat("%s start. %s, %s, unit: %f", EA_NAME, symbol, period, unit));
   st.init();
   return(INIT_SUCCEEDED);
}

void OnTick() {
   st.recvTick();
}

void OnDeinit(const int reason) {}

double OnTester() {
   return Util::calcWinRatio();
}

void OnTradeTransaction(const MqlTradeTransaction &tran, const MqlTradeRequest &request, const MqlTradeResult &result) {
   Util::logProfit(tran, request, result);   
}
