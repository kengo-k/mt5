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
   return "101";
}

/**
 * ・上から順に短期、長期、超長期MAが並んでいる状態でMACDのシグナルブレイク時に買い
 * ・逆も同様
 */
ENUM_ENTRY_COMMAND open(
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {
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
   
   if (shortMA_latest > longMA_latest && longMA_latest > longlongMA_latest) {
      if (checkUpperBreak(macd_latest, macd_prev, signal_latest, signal_prev)) {
         NOTIFY_MESSAGE(config.eaName, "[INFO] 買いサインが発生しました");
         return ENTRY_COMMAND_BUY;
      }   
   }
   
   if (shortMA_latest < longMA_latest && longMA_latest < longlongMA_latest) {
      if (checkLowerBreak(macd_latest, macd_prev, signal_latest, signal_prev)) {
         NOTIFY_MESSAGE(config.eaName, "[INFO] 売りサインが発生しました");
         return ENTRY_COMMAND_SELL;
      }      
   }

   return ENTRY_COMMAND_NOOP;
}
