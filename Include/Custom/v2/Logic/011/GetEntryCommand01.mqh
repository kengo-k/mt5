#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Logic/011/Context.mqh>
#include <Custom/v2/Logic/011/IGetEntryCommand.mqh>

extern Context __context;

// BUY/SELL(もしくは何もしない)を判断するロジック
// 判定したコマンドがトレンド方向と一致した場合のみそのコマンドを返す
// それ以外はすべて何もしないこととする
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

      ENUM_ENTRY_COMMAND command = ENTRY_COMMAND_NOOP;
      if (latestMa > latestLongMa) {
         command = ENTRY_COMMAND_BUY;
      } else {
         command = ENTRY_COMMAND_SELL;
      }

      if (command == trend) {
         return command;
      } else {
         return ENTRY_COMMAND_NOOP;
      }
   }

};
