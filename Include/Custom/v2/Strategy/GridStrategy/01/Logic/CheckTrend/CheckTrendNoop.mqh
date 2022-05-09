#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>

// strategy011で使用するトレンド判定ロジック実装
// 何も判定をしない実装
// ※比較検討用
class CheckTrend : public ICheckTrend {
public:

   ENUM_ENTRY_COMMAND exec() {
      return ENTRY_COMMAND_NOOP;
   }
};
