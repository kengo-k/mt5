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

extern ENUM_GRID_HEDGE_MODE _GRID_HEDGE_MODE;

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

      if (_GRID_HEDGE_MODE == GRID_HEDGE_MODE_ONESIDE_CLOSE) {
         PositionSummary gridSummary;
         PositionSummary hedgeSummary;

         CArrayList<PosInfo*> gridBuyRed;
         CArrayList<PosInfo*> gridBuyBlack;
         CArrayList<PosInfo*> gridSellRed;
         CArrayList<PosInfo*> gridSellBlack;

         CArrayList<PosInfo*> hedgeBuyRed;
         CArrayList<PosInfo*> hedgeBuyBlack;
         CArrayList<PosInfo*> hedgeSellRed;
         CArrayList<PosInfo*> hedgeSellBlack;

         Position::summaryPosition(&gridSummary, &gridBuyRed, &gridBuyBlack, &gridSellRed, &gridSellBlack, MAGIC_NUMBER_MAIN);
         Position::summaryPosition(&hedgeSummary, &hedgeBuyRed, &hedgeBuyBlack, &hedgeSellRed, &hedgeSellBlack, MAGIC_NUMBER_HEDGE);

         bool isBuyRedCloseable = false;
         bool isBuyBlackCloseable = false;
         bool isSellRedCloseable = false;
         bool isSellBlackCloseable = false;

         if (hedgeSummary.buy + gridSummary.buy > __config.totalHedgeTp) {
            isBuyRedCloseable = true;
            isBuyBlackCloseable = true;
         }

         if (hedgeSummary.sell + gridSummary.sell > __config.totalHedgeTp) {
            isSellRedCloseable = true;
            isSellBlackCloseable = true;
         }

         if (isBuyRedCloseable) {
            this.addClosePositions(&gridBuyRed);
            this.addClosePositions(&hedgeBuyRed);
         }

         if (isBuyBlackCloseable) {
            this.addClosePositions(&gridBuyBlack);
            this.addClosePositions(&hedgeBuyBlack);
         }

         if (isSellRedCloseable) {
            this.addClosePositions(&gridSellRed);
            this.addClosePositions(&hedgeSellRed);
         }

         if (isSellBlackCloseable) {
            this.addClosePositions(&gridSellBlack);
            this.addClosePositions(&hedgeSellBlack);
         }

         Position::deletePositionList(&gridBuyRed);
         Position::deletePositionList(&gridBuyBlack);
         Position::deletePositionList(&gridSellRed);
         Position::deletePositionList(&gridSellBlack);

         Position::deletePositionList(&hedgeBuyRed);
         Position::deletePositionList(&hedgeBuyBlack);
         Position::deletePositionList(&hedgeSellRed);
         Position::deletePositionList(&hedgeSellBlack);
      }

      if (_GRID_HEDGE_MODE == GRID_HEDGE_MODE_ALL_CLOSE) {

         PositionSummary summary;

         CArrayList<PosInfo*> buyRed;
         CArrayList<PosInfo*> buyBlack;
         CArrayList<PosInfo*> sellRed;
         CArrayList<PosInfo*> sellBlack;

         Position::summaryPosition(&summary, &buyRed, &buyBlack, &sellRed, &sellBlack, 0);

         bool closeable = false;

         if (summary.total > __config.totalHedgeTp) {
            closeable = true;
         }

         if (closeable) {
            this.addClosePositions(&buyRed);
            this.addClosePositions(&buyBlack);
            this.addClosePositions(&sellRed);
            this.addClosePositions(&sellBlack);
         }

         Position::deletePositionList(&buyRed);
         Position::deletePositionList(&buyBlack);
         Position::deletePositionList(&sellRed);
         Position::deletePositionList(&sellBlack);
      }
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
