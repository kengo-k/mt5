#include <Custom/v2/Common/Constant.mqh>

// エントリ判断をする
interface IGetEntryCommand {
   ENUM_ENTRY_COMMAND exec();
};
