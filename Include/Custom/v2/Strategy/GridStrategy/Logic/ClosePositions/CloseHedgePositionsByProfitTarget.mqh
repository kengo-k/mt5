#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/DateWrapper.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>
#include <Custom/v2/Common/TimeframeSwitchHandler.mqh>

#include <Custom/v2/Strategy/GridStrategy/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/ClosePositions/ClosePositionsBase.mqh>

extern Config *__config;
extern ICheckTrend *__checkTrend;

// ヘッジポジションのクローズロジック実装
// ・トータルの利益が目標額を超えた場合に全てのポジションを決済する
class ClosePositions: public ClosePositionsBase {
public:

   ClosePositions(ENUM_TIMEFRAMES closeTimeframes) {
      this.handler.set(closeTimeframes);
   }

   void exec() {

      this.handler.update();
      if (!this.handler.isSwitched()) {
         return;
      }

      int posCount = PositionsTotal();
      if (posCount == 0) {
         return;
      }

      PosInfoComparer asc(true);
      PosInfoComparer desc(false);

      PositionSummary summary;
      CArrayList<PosInfo*> buyRed;
      CArrayList<PosInfo*> buyBlack;
      CArrayList<PosInfo*> sellRed;
      CArrayList<PosInfo*> sellBlack;
      Position::summaryPosition(&summary, &buyRed, &buyBlack, &sellRed, &sellBlack, MAGIC_NUMBER_HEDGE);

      buyRed.Sort(&desc);
      buyBlack.Sort(&asc);
      sellRed.Sort(&desc);
      sellBlack.Sort(&asc);

      bool isBuyRedCloseable = false;
      bool isBuyBlackCloseable = false;
      bool isSellRedCloseable = false;
      bool isSellBlackCloseable = false;

      int buyRedCloseCount = -1;
      int buyBlackCloseCount = -1;
      int sellRedCloseCount = -1;
      int sellBlackCloseCount = -1;

      if (summary.total > __config.totalHedgeTp) {
         isBuyRedCloseable = true;
         isBuyBlackCloseable = true;
         isSellRedCloseable = true;
         isSellBlackCloseable = true;
      }

      if (isBuyRedCloseable) {
         this.addClosePositions(&buyRed, buyRedCloseCount);
      }

      if (isBuyBlackCloseable) {
         this.addClosePositions(&buyBlack, buyBlackCloseCount);
      }

      if (isSellRedCloseable) {
         this.addClosePositions(&sellRed, sellRedCloseCount);
      }

      if (isSellBlackCloseable) {
         this.addClosePositions(&sellBlack, sellBlackCloseCount);
      }

      Position::deletePositionList(&buyRed);
      Position::deletePositionList(&buyBlack);
      Position::deletePositionList(&sellRed);
      Position::deletePositionList(&sellBlack);
   }

   int getCloseCount(double black, CArrayList<PosInfo*> *redList) {
      int closeCount = 0;
      double red = 0;
      int count = redList.Count();
      for (int i = 0; i < count; i++) {
         PosInfo *p;
         redList.TryGetValue(i, p);
         red += MathAbs(p.profitAndSwap);
         if (red > black) {
            break;
         }
         closeCount++;
      }
      return closeCount;
   }

   void addClosePositions(CArrayList<PosInfo*> *positions, int closeCount) {
      int count = positions.Count();
      for (int i = 0; i < count; i++) {
         if (
            closeCount < 0
               || i < (closeCount -1)
         ) {
            PosInfo *p;
            positions.TryGetValue(i, p);
            Request* req = RequestContainer::createRequest();
            Order::createCloseRequest(req.item, p.positionTicket, p.magicNumber);
            this.orderQueue.add(req);
         }
      }
   }

private:
   TimeframeSwitchHandler handler;
};
