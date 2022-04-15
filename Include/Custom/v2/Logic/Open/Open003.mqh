#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Logic/Exec/Exec001.mqh>

/**
 * エントリ処理
 */
class Open003 {
public:
   static void open(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
      
      MqlRates prices[];
      ArraySetAsSeries(prices, false);
      CopyRates(Symbol(), PERIOD_CURRENT, 0, 2, prices);
      
      MqlRates currentRate = prices[1];
      MqlRates latestRate = prices[0];
      
      CopyBuffer(contextMain.longMaHandle, 0, 0, 2, contextMain.longMA);
      CopyBuffer(contextMain.longlongMaHandle, 0, 0, 2, contextMain.longlongMA);

      double longMA_current = contextMain.longMA[1];
      double longlongMA_current = contextMain.longlongMA[1];
      double longMA_latest = contextMain.longMA[0];
      double longlongMA_latest = contextMain.longlongMA[0];

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;

      if (longMA_latest > longlongMA_latest) {
         if (Chart::isInOpenClose(latestRate, longMA_latest)) {
            if (currentRate.open > longMA_current) {
               command = ENTRY_COMMAND_BUY;
            }
         }
      }

      if (longMA_latest < longlongMA_latest) {
         if (Chart::isInOpenClose(latestRate, longMA_latest)) {
            if (currentRate.open < longMA_current) {
               command = ENTRY_COMMAND_SELL;
            }
         }
      }

      Exec001::exec(command, contextMain, contextSub, config);
   }
};