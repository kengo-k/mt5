#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Config/Config003.mqh>
#include <Custom/v2/Logic/Exec/Exec003.mqh>

/**
 * エントリ処理
 */
class Open004 {
public:
   static void open(Context002 &contextMain, Context002 &contextSub, Config003 &config) {

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

      Exec003::exec(command, contextMain, contextSub, config);
   }
};
