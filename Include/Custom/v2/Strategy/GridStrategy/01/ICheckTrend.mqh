#include <Custom/v2/Common/Constant.mqh>

// トレンド判定処理を行う
interface ICheckTrend {
   void exec();
   ENUM_ENTRY_COMMAND getCurrentTrend();
   ENUM_ENTRY_COMMAND getPrevTrend();
   bool hasTrendSwitchSign();
};
