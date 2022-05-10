#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/DateWrapper.mqh>
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

// ヘッジポジションのクローズロジック実装(※月足想定)
// ・月が切り替わったタイミングで一定以上の黒字ポジションを決済
// ・トレンド転換で残りの全ポジションを決済
class CloseHedgePositions: public CloseHedgePositionsBase {
public:

   CloseHedgePositions() {
      this.latestDate = MAX_YYYYMM;
   }

   void exec() {
      LoggerFacade logger;

      DateWrapper date;
      string currentDate = date.getYYYYMM();
      if (this.latestDate == MAX_YYYYMM) {
         this.latestDate = currentDate;
      }
      string prevDate = this.latestDate;
      this.latestDate = currentDate;

      int posCount = PositionsTotal();
      if (posCount == 0) {
         this.latestDate = currentDate;
         return;
      }

      PositionSummary hedgeSummary;
      Position::summaryPosition(hedgeSummary, MAGIC_NUMBER_HEDGE);

      bool isRequiredClose = false;
      bool closeAll = false;

      if (this.latestDate != prevDate) {
         isRequiredClose = true;
         if (__checkTrend.getCurrentTrend() != __checkTrend.getPrevTrend()) {
            closeAll = true;
         }
      }

      if (!isRequiredClose) {
         return;
      }

      CArrayList<PosInfo*> buyHedgeList;
      CArrayList<PosInfo*> sellHedgeList;

      for (int i = 0; i < posCount; i++) {
         ulong posTicket = PositionGetTicket(i);
         if (posTicket) {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
            long posMagicNumber = PositionGetInteger(POSITION_MAGIC);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double swap = PositionGetDouble(POSITION_SWAP);
            PosInfo *p = new PosInfo();
            p.positionTicket = posTicket;
            p.profitAndSwap = profit + swap;
            p.swap = swap;
            p.magicNumber = posMagicNumber;
            if(posMagicNumber == MAGIC_NUMBER_HEDGE && posType == POSITION_TYPE_BUY) {
               buyHedgeList.Add(p);
            } else if(posMagicNumber == MAGIC_NUMBER_HEDGE && posType == POSITION_TYPE_SELL) {
               sellHedgeList.Add(p);
            }
         }
      }

      this.addClosePositions(&buyHedgeList, closeAll);
      this.addClosePositions(&sellHedgeList, closeAll);

      Position::deletePositionList(&buyHedgeList);
      Position::deletePositionList(&sellHedgeList);
   }

   void addClosePositions(CArrayList<PosInfo*> *positions, bool closeAll) {
      LoggerFacade logger;
      int count = positions.Count();
      for (int i = 0; i < count; i++) {
         PosInfo *p;
         positions.TryGetValue(i, p);
         bool close = false;
         if (closeAll) {
            close = true;
         } else {
            if (p.profitAndSwap > __config.tp) {
               close = true;
            }
         }
         if (close) {
            Request* req = RequestContainer::createRequest();
            Order::createCloseRequest(req.item, p.positionTicket, p.magicNumber);
            this.orderQueue.add(req);
         }
      }
   }
private:
   // 月の切り替わりを管理するために使用する日付文字列
   string latestDate;
};
