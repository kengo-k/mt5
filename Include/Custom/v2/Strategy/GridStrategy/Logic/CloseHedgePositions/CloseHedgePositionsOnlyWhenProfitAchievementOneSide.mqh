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
#include <Custom/v2/Strategy/GridStrategy/Logic/CloseHedgePositions/CloseHedgePositionsBase.mqh>

extern Config *__config;
extern ICheckTrend *__checkTrend;

// ヘッジポジションのクローズロジック実装
// ・トータルの利益が目標額を超えた場合に全てのポジションを決済する
class CloseHedgePositions: public CloseHedgePositionsBase {
public:

   CloseHedgePositions(ENUM_TIMEFRAMES closeTimeframes) {
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

      PositionSummary summary;
      CArrayList<PosInfo*> buyRed;
      CArrayList<PosInfo*> buyBlack;
      CArrayList<PosInfo*> sellRed;
      CArrayList<PosInfo*> sellBlack;
      Position::summaryPosition(&summary, &buyRed, &buyBlack, &sellRed, &sellBlack, MAGIC_NUMBER_HEDGE);

      bool isBuyRedCloseable = false;
      bool isBuyBlackCloseable = false;
      bool isSellRedCloseable = false;
      bool isSellBlackCloseable = false;

      if (summary.buy > __config.totalHedgeTp) {
         isBuyRedCloseable = true;
         isBuyBlackCloseable = true;
      }

      if (summary.sell > __config.totalHedgeTp) {
         isSellRedCloseable = true;
         isSellBlackCloseable = true;
      }

      if (isBuyRedCloseable) {
         this.addClosePositions(&buyRed);
      }

      if (isBuyBlackCloseable) {
         this.addClosePositions(&buyBlack);
      }

      if (isSellRedCloseable) {
         this.addClosePositions(&sellRed);
      }

      if (isSellBlackCloseable) {
         this.addClosePositions(&sellBlack);
      }

      Position::deletePositionList(&buyRed);
      Position::deletePositionList(&buyBlack);
      Position::deletePositionList(&sellRed);
      Position::deletePositionList(&sellBlack);
   }

   void addClosePositions(CArrayList<PosInfo*> *positions) {
      int count = positions.Count();
      for (int i = 0; i < count; i++) {
         PosInfo *p;
         positions.TryGetValue(i, p);
         Request* req = RequestContainer::createRequest();
         Order::createCloseRequest(req.item, p.positionTicket, p.magicNumber);
         this.orderQueue.add(req);
      }
   }

private:
   TimeframeSwitchHandler handler;
};
