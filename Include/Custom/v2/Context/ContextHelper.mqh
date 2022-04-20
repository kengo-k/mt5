#include <Custom/v2/Context/Context001.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Config/Config002.mqh>
#include <Custom/v2/Config/Config003.mqh>
#include <Custom/v2/Config/Config004.mqh>

/**
 * コンテキスト初期化処理のヘルパーメソッド集
 */
class ContextHelper {
public:

   static void initContext(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
      if (config.shortMaPeriod > 0) {
         contextMain.shortMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.shortMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if (config.longMaPeriod > 0) {
         contextMain.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if (config.longlongMaPeriod > 0) {
         contextMain.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if (config.macdPeriod[0] > 0) {
         contextMain.macdHandle = iMACD(Symbol(), PERIOD_CURRENT, config.macdPeriod[0], config.macdPeriod[1], config.macdPeriod[2], PRICE_CLOSE);
      }
   }

   static void initContext(Context002 &contextMain, Context002 &contextSub, Config002 &config) {
      if (config.longMaPeriod > 0) {
         contextMain.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if (config.longlongMaPeriod > 0) {
         contextMain.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
   }

   static void initContext(Context002 &contextMain, Context002 &contextSub, Config003 &config) {
      if (config.longMaPeriod > 0) {
         contextMain.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if (config.longlongMaPeriod > 0) {
         contextMain.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }   
   }
   
   static void initContext(Context002 &contextMain, Context002 &contextSub, Config004 &config) {
      if (config.longMaPeriod > 0) {
         contextMain.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }
      if (config.longlongMaPeriod > 0) {
         contextMain.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      }   
   }   

};
