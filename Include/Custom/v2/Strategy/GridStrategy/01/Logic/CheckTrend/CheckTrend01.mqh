#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>

extern Config *__config;
extern Context __context;

// トレンド判定ロジック実装
// ・直近2本のMAクロス
class CheckTrend : public ICheckTrend {
public:

   CheckTrend() {
      latestHedgeDirection = ENTRY_COMMAND_NOOP;
      currentHedgeDirection = ENTRY_COMMAND_NOOP;
   }

   ENUM_ENTRY_COMMAND exec() {
      CopyBuffer(__context.hedgeMaHandle, 0, 0, 2, __context.hedgeMa);
      CopyBuffer(__context.hedgeLongMaHandle, 0, 0, 2, __context.hedgeLongMa);

      double latestMa = __context.hedgeMa[0];
      double latestLongMa = __context.hedgeLongMa[0];

      ENUM_ENTRY_COMMAND direction = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         direction = ENTRY_COMMAND_BUY;
      } else {
         direction = ENTRY_COMMAND_SELL;
      }

      return direction;
   }

private:
   ENUM_ENTRY_COMMAND latestHedgeDirection;
   ENUM_ENTRY_COMMAND currentHedgeDirection;
};
