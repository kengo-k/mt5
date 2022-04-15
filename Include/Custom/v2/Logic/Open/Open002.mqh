#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Logic/Exec/Exec001.mqh>

/**
 * エントリ処理
 */
class Open002 {
public:
   static void open(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
            
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

      Exec001::exec(command, contextMain, contextSub, config);
   }
};
