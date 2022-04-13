#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Context/Context001.mqh>

/**
 * コンテキスト初期化処理のヘルパーメソッド集
 */
class ContextHelper {
public:
   static void initContext001(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
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
};
