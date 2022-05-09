#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>

extern Context __context;
extern ICheckTrend *__checkTrend;

// エントリ判断ロジック実装
// 判定したエントリがトレンド方向と一致した場合のみエントリする
class GetEntryCommand : public IGetEntryCommand {
public:

   ENUM_ENTRY_COMMAND exec() {

      CopyBuffer(__context.orderMaHandle, 0, 0, 2, __context.orderMa);
      CopyBuffer(__context.orderLongMaHandle, 0, 0, 2, __context.orderLongMa);

      double latestMa = __context.orderMa[0];
      double latestLongMa = __context.orderLongMa[0];

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         command = ENTRY_COMMAND_BUY;
      } else {
         command = ENTRY_COMMAND_SELL;
      }

      if (command == __checkTrend.getCurrentTrend()) {
         return command;
      } else {
         return ENTRY_COMMAND_NOOP;
      }
   }

};
