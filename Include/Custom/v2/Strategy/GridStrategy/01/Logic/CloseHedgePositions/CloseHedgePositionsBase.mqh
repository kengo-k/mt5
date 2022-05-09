#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/01/ICloseHedgePositions.mqh>

// ヘッジポジションのクローズロジックの共通親クラス
class CloseHedgePositionsBase: public ICloseHedgePositions {
public:

   void setCloseOrderQueue(RequestContainer *_orderQueue) {
      this.orderQueue = _orderQueue;
   }

   void setCurrentTrend(ENUM_ENTRY_COMMAND _currentTrend) {
      this.currentTrend = _currentTrend;
   }

   void setLatestTrend(ENUM_ENTRY_COMMAND _latestTrend) {
      this.latestTrend = _latestTrend;
   }

protected:

   RequestContainer *orderQueue;
   ENUM_ENTRY_COMMAND currentTrend;
   ENUM_ENTRY_COMMAND latestTrend;

   ENUM_ENTRY_COMMAND getCurrentTrend() {
      return this.currentTrend;
   }

   ENUM_ENTRY_COMMAND getLatestTrend() {
      return this.latestTrend;
   }

};
