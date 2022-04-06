// Libraries/Custom/Logics/filterCommand1.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>

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

   return accept;
}
