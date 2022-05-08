#include <Custom/v2/Common/Constant.mqh>

// strategy011で使用するトレンド判定ロジック実装
// 何も判定をしない実装
// ※比較検討用
class CheckTrend {
public:

   ENUM_ENTRY_COMMAND exec() {
      return ENTRY_COMMAND_NOOP;
   }
};
