#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>

// トレンド判定ロジック実装
// ・共通親クラス
class CheckTrendBase : public ICheckTrend {
public:

   ENUM_ENTRY_COMMAND getCurrentTrend() {
      return this.currentTrend;
   }

   ENUM_ENTRY_COMMAND getPrevTrend() {
      return this.prevTrend;
   }

   bool hasTrendSwitchSign() {
      return this.trendSwitchSign;
   }

protected:

   ENUM_ENTRY_COMMAND currentTrend;
   ENUM_ENTRY_COMMAND prevTrend;
   bool trendSwitchSign;

   void setCurrentTrend(ENUM_ENTRY_COMMAND _currentTrend) {
      this.currentTrend = _currentTrend;
   }

   void setPrevTrend(ENUM_ENTRY_COMMAND _prevTrend) {
      this.prevTrend = _prevTrend;
   }

   void setTrendSwitchSign(bool sign) {
      this.trendSwitchSign = sign;
   }
};
