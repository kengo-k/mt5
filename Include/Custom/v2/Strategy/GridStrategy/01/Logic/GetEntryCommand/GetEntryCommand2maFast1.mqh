#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>

extern Context __context;

// エントリ判断ロジック実装
// 判定したエントリがトレンド方向と一致した場合のみエントリする
// ・ただし直近の短期MAが逆行した場合にエントリしない
class GetEntryCommand : public IGetEntryCommand {
public:

   ENUM_ENTRY_COMMAND exec(ENUM_ENTRY_COMMAND trend) {

      if (trend == ENTRY_COMMAND_NOOP) {
         return ENTRY_COMMAND_NOOP;
      }

      CopyBuffer(__context.orderMaHandle, 0, 0, 2, __context.orderMa);
      CopyBuffer(__context.orderLongMaHandle, 0, 0, 2, __context.orderLongMa);

      double latestMa = __context.orderMa[0];
      double latestLongMa = __context.orderLongMa[0];
      double currentMa = __context.orderMa[1];

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         if (currentMa < latestMa) {
            command = ENTRY_COMMAND_BUY;
         }
      } else {
         if (currentMa > latestMa) {
            command = ENTRY_COMMAND_SELL;
         }
      }

      if (command == trend) {
         return command;
      } else {
         return ENTRY_COMMAND_NOOP;
      }
   }

};
