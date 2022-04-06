// Libraries/Custom/Logics/filterCommand1.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import
#include <Custom/SlackLib.mqh>

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

bool filterCommand(
   ENUM_ENTRY_COMMAND command,
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {

   if (command == ENTRY_COMMAND_NOOP) {
      return false;
   }

   bool accept = false;

   CopyBuffer(contextMain.macdHandle, 0, 0, 2, contextMain.macd);
   double macd_latest = contextMain.macd[0]; // 確定した最新の一つ前のMACD値。

   if (command == ENTRY_COMMAND_BUY) {
      if (macd_latest > 0) {
         accept = true;
      }
   } else {
      if (macd_latest < 0) {
         accept = true;
      }
   }

   NOTIFY_MESSAGE(config.eaName, StringFormat("[INFO] accept? %d", accept));
   return accept;
   //return false;
   //return true;
}
