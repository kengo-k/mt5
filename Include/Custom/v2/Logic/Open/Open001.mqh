#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Logic/Exec/Exec001.mqh>

/**
 * エントリ処理
 */
class Open001 {
public:
   static void open(Context001 &contextMain, Context001 &contextSub, Config001 &config) {

      CopyBuffer(contextMain.shortMaHandle, 0, 0, 2, contextMain.shortMA);
      CopyBuffer(contextMain.longMaHandle, 0, 0, 2, contextMain.longMA);
      CopyBuffer(contextMain.longlongMaHandle, 0, 0, 2, contextMain.longlongMA);
      CopyBuffer(contextMain.macdHandle, 0, 0, 3, contextMain.macd);
      CopyBuffer(contextMain.macdHandle, 1, 0, 3, contextMain.signal);

      double shortMA_latest = contextMain.shortMA[0];
      double longMA_latest = contextMain.longMA[0];
      double longlongMA_latest = contextMain.longlongMA[0];

      double macd_latest = contextMain.macd[1];
      double macd_prev = contextMain.macd[0];
      double signal_latest = contextMain.signal[1];
      double signal_prev = contextMain.signal[0];

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      if (shortMA_latest > longMA_latest && longMA_latest > longlongMA_latest) {
         if (Util::checkUpperBreak(macd_latest, macd_prev, signal_latest, signal_prev)) {
            command =  ENTRY_COMMAND_BUY;
         }
      }

      if (shortMA_latest < longMA_latest && longMA_latest < longlongMA_latest) {
         if (Util::checkLowerBreak(macd_latest, macd_prev, signal_latest, signal_prev)) {
            command =  ENTRY_COMMAND_SELL;
         }
      }

      Exec001::exec(command, contextMain, contextSub, config);
   }
};
