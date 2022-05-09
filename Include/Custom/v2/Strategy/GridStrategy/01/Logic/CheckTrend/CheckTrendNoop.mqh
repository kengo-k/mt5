#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>

// トレンド判定ロジック実装
// ・判定を何も行わない
// ※比較用
class CheckTrend : public ICheckTrend {
public:

   ENUM_ENTRY_COMMAND exec() {
      return ENTRY_COMMAND_NOOP;
   }
};
