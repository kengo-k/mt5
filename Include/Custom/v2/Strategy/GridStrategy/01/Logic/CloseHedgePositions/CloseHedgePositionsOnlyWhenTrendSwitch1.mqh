#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/01/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CloseHedgePositions/CloseHedgePositionsBase.mqh>

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

      PositionSummary mainSummary;
      PositionSummary hedgeSummary;
      Position::summaryPosition(hedgeSummary, MAGIC_NUMBER_HEDGE);

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

      CArrayList<PosInfo*> buyHedgeList;
      CArrayList<PosInfo*> sellHedgeList;

      for (int i = 0; i < posCount; i++) {
         ulong posTicket = PositionGetTicket(i);
         if (posTicket) {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
            PosInfo *p = new PosInfo();
            Position::setPosInfo(p);
            if(posType == POSITION_TYPE_BUY) {
               buyHedgeList.Add(p);
            } else {
               sellHedgeList.Add(p);
            }
         }
      }

      this.addClosePositions(&buyHedgeList);
      this.addClosePositions(&sellHedgeList);

      Position::deletePositionList(&buyHedgeList);
      Position::deletePositionList(&sellHedgeList);
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
