#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CheckTrend/CheckTrendBase.mqh>

// トレンド判定ロジック実装
// ・判定を何も行わない
// ※比較用
class CheckTrend : public CheckTrendBase {
public:

   void exec() {
   }
};
