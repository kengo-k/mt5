// in Libraries/Custom/v1/opener

#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>
#include <Custom/v1/SlackLib.mqh>

#import "Custom/v1/common/common.ex5"
   int notifySlack(string message, string channel);
   bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal);
   bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal);
#import

string getOpenerName() export {
   return "051";
}

/**
 * 短期MAが長期MAをブレイクした瞬間にエントリする
 */
ENUM_ENTRY_COMMAND open(
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {
   CopyBuffer(contextMain.shortMaHandle, 0, 0, 3, contextMain.shortMA);
   CopyBuffer(contextMain.longMaHandle, 0, 0, 3, contextMain.longMA);

   double shortMA_latest = contextMain.shortMA[1];
   double longMA_latest = contextMain.longMA[1];
   double shortMA_prev = contextMain.shortMA[0];
   double longMA_prev = contextMain.longMA[0];

   if (shortMA_prev < longMA_prev && shortMA_latest > longMA_latest) {
      NOTIFY_MESSAGE(config.eaName, "[INFO] 買いサインが発生しました");
      return ENTRY_COMMAND_BUY;
   }

   if (shortMA_prev > longMA_prev && shortMA_latest < longMA_latest) {
      NOTIFY_MESSAGE(config.eaName, "[INFO] 売りサインが発生しました");
      return ENTRY_COMMAND_SELL;
   }

   return ENTRY_COMMAND_NOOP;
}
