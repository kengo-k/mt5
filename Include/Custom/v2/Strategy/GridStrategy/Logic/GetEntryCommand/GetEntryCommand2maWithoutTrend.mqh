#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Strategy/GridStrategy/Context.mqh>
#include <Custom/v2/Strategy/GridStrategy/IGetEntryCommand.mqh>

extern Context __context;

// エントリ判断ロジック実装
// トレンドは無視して直近2本のMAクロスでのみ判定を行う
// ※比較用
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

      return command;
   }

};
