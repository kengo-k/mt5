/**
 * エントリ:
 */
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Context/Context001.mqh>
#include <Custom/v2/Context/ContextHelper.mqh>
#include <Custom/v2/Logic/Logic001.mqh>
#include <Custom/v2/Builder/StrategyBuilder001.mqh>

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

LogicFactory __logicFactory;
Logic __logic = __logicFactory.createLogic();

ConfigFactory __configFactory;
Config001 __config = __configFactory.create(
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
   ContextHelper helper;
   helper.initContext001(main, sub, config);
}

StrategyBuilder001<Config001, Context001> st(
   __config
   , initContext
   , __logic.fnOpen
   , __logic.fnClose
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
