#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/IClosePositions.mqh>

// ヘッジポジションのクローズロジック実装
// 何もしない実装
class ClosePositions: public IClosePositions {
public:
   void exec() {}
   void setCloseOrderQueue(RequestContainer *_orderQueue) {}
};
