#include <Custom/v2/Common/RequestContainer.mqh>

// ヘッジポジションのクローズ処理を行う
interface ICloseHedgePositions {
   void exec();
   void setCloseOrderQueue(RequestContainer *_orderQueue);
};
