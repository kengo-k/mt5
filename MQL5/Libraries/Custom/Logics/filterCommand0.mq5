// Libraries/Custom/Logics/filterCommand0.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import
#include <Custom/v1/SlackLib.mqh>

#include <Custom/v1/SimpleMACDConfig.mqh>
#include <Custom/v1/SimpleMACDContext.mqh>

bool filterCommand(
   ENUM_ENTRY_COMMAND command,
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {
   return true;
}
