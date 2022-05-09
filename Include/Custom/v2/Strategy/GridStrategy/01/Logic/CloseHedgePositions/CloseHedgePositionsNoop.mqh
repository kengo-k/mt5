#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/01/ICloseHedgePositions.mqh>

// ヘッジポジションのクローズロジック実装
// 何もしない実装
class CloseHedgePositions: public ICloseHedgePositions {
public:
   void exec() {}
   void setCloseOrderQueue(RequestContainer *_orderQueue) {}
};
