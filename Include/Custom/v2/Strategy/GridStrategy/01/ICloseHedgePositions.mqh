#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

// ヘッジポジションのクローズ処理を行う
interface ICloseHedgePositions {
   void exec();
   void setCloseOrderQueue(RequestContainer *_orderQueue);
   void setCurrentTrend(ENUM_ENTRY_COMMAND _currentTrend);
   void setLatestTrend(ENUM_ENTRY_COMMAND _latestTrend);
};
