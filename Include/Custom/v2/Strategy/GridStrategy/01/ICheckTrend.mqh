#include <Custom/v2/Common/Constant.mqh>

interface ICheckTrend {
   void exec();
   ENUM_ENTRY_COMMAND getCurrentTrend();
   ENUM_ENTRY_COMMAND getPrevTrend();
   bool hasTrendSwitchSign();
};
