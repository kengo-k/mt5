#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/CloseHedgePositions/CloseHedgePositionsBase.mqh>

extern Config *__config;
extern ICheckTrend *__checkTrend;

// ヘッジポジションのクローズロジック実装
// トレンドが転換もしくは転換予兆が発生した時点ですべてクローズする
class CloseHedgePositions: public CloseHedgePositionsBase {
public:

   void exec() {

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

      bool isRequireClose = false;

      if (__checkTrend.getCurrentTrend() != __checkTrend.getPrevTrend()) {
         isRequireClose = true;
      }

      if (__checkTrend.getCurrentTrend() == __checkTrend.getPrevTrend()
            && __checkTrend.hasTrendSwitchSign()) {
         isRequireClose = true;
      }

      if (!isRequireClose) {
         return;
      }

      this.addClosePositions(&buyRed);
      this.addClosePositions(&buyBlack);
      this.addClosePositions(&sellRed);
      this.addClosePositions(&sellBlack);

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

};
