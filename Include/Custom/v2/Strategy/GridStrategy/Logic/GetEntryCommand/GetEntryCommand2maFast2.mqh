#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/IGetEntryCommand.mqh>

extern Context __context;
extern ICheckTrend *__checkTrend;

// エントリ判断ロジック実装
// 判定したエントリがトレンド方向と一致した場合のみエントリする
// ・ただし現在の短期MAが逆行した場合にエントリしない
class GetEntryCommand : public IGetEntryCommand {
public:

   ENUM_ENTRY_COMMAND exec() {

      CopyBuffer(__context.orderMaHandle, 0, 0, 2, __context.orderMa);
      CopyBuffer(__context.orderLongMaHandle, 0, 0, 2, __context.orderLongMa);

      double latestMa = __context.orderMa[0];
      double latestLongMa = __context.orderLongMa[0];
      double currentMa = __context.orderMa[1];

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         if (latestMa < currentMa) {
            command = ENTRY_COMMAND_BUY;
         }
      } else {
         if (latestMa > currentMa) {
            command = ENTRY_COMMAND_SELL;
         }
      }

      if (command == __checkTrend.getCurrentTrend()
            && !__checkTrend.hasTrendSwitchSign()) {
         return command;
      } else {
         return ENTRY_COMMAND_NOOP;
      }
   }

};
