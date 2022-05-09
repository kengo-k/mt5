#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Logic/011/Config.mqh>
#include <Custom/v2/Logic/011/Context.mqh>
#include <Custom/v2/Logic/011/ICheckTrend.mqh>

extern Config *__config;
extern Context __context;

// strategy011で使用するトレンド判定ロジック実装
// シンプルな直近MAクロスを使うが短期MAが逆行したらその時点でトレンド反転の兆しと判断する
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
      double currentMa = __context.hedgeMa[1];

      ENUM_ENTRY_COMMAND direction = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         if (latestMa < currentMa) {
            direction = ENTRY_COMMAND_BUY;
         }
      } else {
         if (latestMa > currentMa) {
            direction = ENTRY_COMMAND_SELL;
         }
      }

      return direction;
   }

private:
   ENUM_ENTRY_COMMAND latestHedgeDirection;
   ENUM_ENTRY_COMMAND currentHedgeDirection;
};