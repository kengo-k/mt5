/**
 * エントリ:
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Config/Config002.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Context/ContextHelper.mqh>
#include <Custom/v2/Builder/StrategyBuilder001.mqh>
#include <Custom/v2/Logic/Open/Open003.mqh>

const string EA_NAME = "strategy003";
const long MAGIC_NUMBER = 1;
input double SL = 4;
input double TP = 8;
input double VOLUME = 0.1;
input int LONG_MA_PERIOD = 100;
input int LONG_LONG_MA_PERIOD = 200;

Config002 __config = Config002Factory::create(
   EA_NAME
   , MAGIC_NUMBER
   , SL
   , TP
   , VOLUME
   , LONG_MA_PERIOD
   , LONG_LONG_MA_PERIOD
);

void initContext(Context002 &main, Context002 &sub, Config002 &config) {
   ContextHelper::initContext(main, sub, config);
}

void open(Context002 &contextMain, Context002 &contextSub, Config002 &config) {
   Open003::open(contextMain, contextSub, config);
}

void close(Context002 &contextMain, Context002 &contextSub, Config002 &config) {
}

StrategyBuilder001<Config002, Context002> st(
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
