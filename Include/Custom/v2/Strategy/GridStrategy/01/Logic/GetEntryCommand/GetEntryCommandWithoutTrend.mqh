#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>

extern Context __context;

// BUY/SELL(もしくは何もしない)を判断するロジック
// 引数で渡されたトレンドは無視して単純に短期の直近MAでのみ判定を行う
// ※比較検討用
class GetEntryCommand : public IGetEntryCommand {
public:

   ENUM_ENTRY_COMMAND exec(ENUM_ENTRY_COMMAND trend) {

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

      return command;
   }

};
