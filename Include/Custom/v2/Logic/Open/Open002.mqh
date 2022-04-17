#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Config/Config002.mqh>
#include <Custom/v2/Logic/Exec/Exec002.mqh>

/**
 * エントリ処理
 */
class Open002 {
public:
   static void open(Context002 &contextMain, Context002 &contextSub, Config002 &config) {
            
      CopyBuffer(contextMain.longMaHandle, 0, 0, 3, contextMain.longMA);
      CopyBuffer(contextMain.longlongMaHandle, 0, 0, 3, contextMain.longlongMA);

      double longMA_latest = contextMain.longMA[1];
      double longMA_prev = contextMain.longMA[0];
      
      double longlongMA_latest = contextMain.longlongMA[1];
      double longlongMA_prev = contextMain.longlongMA[0];
      
      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      
      if (longMA_latest > longlongMA_latest) {
         if (Chart::isUpperBreak(longMA_latest, longMA_prev, longlongMA_latest, longlongMA_prev)) {
            command = ENTRY_COMMAND_BUY;
         }
      }

      if (longMA_latest < longlongMA_latest) {
         if (Chart::isLowerBreak(longMA_latest, longMA_prev, longlongMA_latest, longlongMA_prev)) {
            command = ENTRY_COMMAND_SELL;
         }
      }

      Exec002::exec(command, contextMain, contextSub, config);
   }
};
