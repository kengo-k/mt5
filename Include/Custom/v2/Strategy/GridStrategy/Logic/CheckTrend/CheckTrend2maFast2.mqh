#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/CheckTrend/CheckTrendBase.mqh>

extern Config *__config;
extern Context __context;

// トレンド判定ロジック実装
// CheckTrend2maの改善版
//
// ・直近2本のMAクロス
// ・ただし現在の短期MA(=つまりまだローソク足が確定せず動いている状態)が判定したトレンドと逆行した場合にトレンド無しとして返す
class CheckTrend : public CheckTrendBase {
public:

   void exec() {

      this.setPrevTrend(this.getCurrentTrend());

      CopyBuffer(__context.hedgeMaHandle, 0, 0, 2, __context.hedgeMa);
      CopyBuffer(__context.hedgeLongMaHandle, 0, 0, 2, __context.hedgeLongMa);

      double latestMa = __context.hedgeMa[0];
      double latestLongMa = __context.hedgeLongMa[0];
      double currentMa = __context.hedgeMa[1];

      ENUM_ENTRY_COMMAND direction = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         this.setCurrentTrend(ENTRY_COMMAND_BUY);
         this.setTrendSwitchSign(latestMa >= currentMa);
      } else {
         this.setCurrentTrend(ENTRY_COMMAND_SELL);
         this.setTrendSwitchSign(latestMa <= currentMa);
      }
   }

};
