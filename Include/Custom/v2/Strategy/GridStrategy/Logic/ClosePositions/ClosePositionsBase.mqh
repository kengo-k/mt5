#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/IClosePositions.mqh>

// ヘッジポジションのクローズロジックの共通親クラス
class ClosePositionsBase: public IClosePositions {
public:

   void setCloseOrderQueue(RequestContainer *_orderQueue) {
      this.orderQueue = _orderQueue;
   }

protected:
   RequestContainer *orderQueue;

};
