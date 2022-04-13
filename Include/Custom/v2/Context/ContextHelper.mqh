#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Context/Context001.mqh>

/**
 * コンテキスト初期化処理のヘルパーメソッド集
 */
class ContextHelper {
public:
   void initContext001(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
      contextMain.shortMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.shortMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      contextMain.longMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      contextMain.longlongMaHandle = iMA(Symbol(), PERIOD_CURRENT, config.longlongMaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      contextMain.macdHandle = iMACD(Symbol(), PERIOD_CURRENT, config.macdPeriod[0], config.macdPeriod[1], config.macdPeriod[2], PRICE_CLOSE);
   }
};
