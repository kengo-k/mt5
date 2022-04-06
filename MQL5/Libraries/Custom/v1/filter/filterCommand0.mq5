// in Libraries/Custom/v1/filter
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
   return true;
}
