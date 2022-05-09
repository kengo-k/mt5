#include <Custom/v2/Common/Constant.mqh>

interface ICheckTrend {
   ENUM_ENTRY_COMMAND exec();
   ENUM_ENTRY_COMMAND getCurrentTrend();
   ENUM_ENTRY_COMMAND getLatestTrend();
};
