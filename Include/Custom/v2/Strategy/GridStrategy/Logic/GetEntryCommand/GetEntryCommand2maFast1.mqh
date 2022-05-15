#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/IGetEntryCommand.mqh>

extern Context __context;
extern ICheckTrend *__checkTrend;

// エントリ判断ロジック実装
// 判定したエントリがトレンド方向と一致した場合のみエントリする
// ・ただし直近の短期MAが逆行した場合にエントリしない
class GetEntryCommand : public IGetEntryCommand {
public:

   ENUM_ENTRY_COMMAND exec() {

      CopyBuffer(__context.orderMaHandle, 0, 0, 3, __context.orderMa);
      CopyBuffer(__context.orderLongMaHandle, 0, 0, 3, __context.orderLongMa);

      double latestMa = __context.orderMa[1];
      double latestLongMa = __context.orderLongMa[1];
      double prevMa = __context.orderMa[0];

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         if (prevMa < latestMa) {
            command = ENTRY_COMMAND_BUY;
         }
      } else {
         if (prevMa > latestMa) {
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
