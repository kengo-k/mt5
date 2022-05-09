#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>

// トレンド判定ロジック実装
// ・共通親クラス
class CheckTrendBase : public ICheckTrend {
public:

   ENUM_ENTRY_COMMAND getCurrentTrend() {
      return this.currentTrend;
   }

   ENUM_ENTRY_COMMAND getLatestTrend() {
      return this.latestTrend;
   }

protected:

   ENUM_ENTRY_COMMAND currentTrend;
   ENUM_ENTRY_COMMAND latestTrend;

   void setCurrentTrend(ENUM_ENTRY_COMMAND _currentTrend) {
      this.currentTrend = _currentTrend;
   }

   void setLatestTrend(ENUM_ENTRY_COMMAND _latestTrend) {
      this.latestTrend = _latestTrend;
   }
};
