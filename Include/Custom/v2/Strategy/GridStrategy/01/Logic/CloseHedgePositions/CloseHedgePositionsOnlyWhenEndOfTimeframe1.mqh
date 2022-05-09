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
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CloseHedgePositions/CloseHedgePositionsBase.mqh>

extern Config *__config;

// ヘッジポジションのクローズロジック実装
// 指定した期間が終了した時点ですべてクローズ
class CloseHedgePositions: public CloseHedgePositionsBase {
public:
   
   CloseHedgePositions() {
      this.yyyymmdd = "99991231";
   }
   
   void exec() {
      LoggerFacade logger;
      
      DateWrapper date;
      string new_yyyymmdd = date.getYYYYMMDD();
      if (this.yyyymmdd == "99991231") {
         this.yyyymmdd = new_yyyymmdd;
      }
      string old_yyyymmdd = this.yyyymmdd;
      this.yyyymmdd = new_yyyymmdd;
      
      int posCount = PositionsTotal();
      if (posCount == 0) {
         this.yyyymmdd = new_yyyymmdd;
         return;
      }

      PositionSummary hedgeSummary;
      Position::summaryPosition(hedgeSummary, MAGIC_NUMBER_HEDGE);

      logger.logDebug(StringFormat("hedge position summary: buy(%d)=%f, sell(%d)=%f", hedgeSummary.buyCount, hedgeSummary.buy, hedgeSummary.sellCount, hedgeSummary.sell), true);
      
      bool isRequiredClose = false;      
      if (new_yyyymmdd != old_yyyymmdd) {
         isRequiredClose = true;
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

      logger.logDebug(StringFormat("buy hedge: %s", Position::getPositionListString(&buyHedgeList)), true);
      logger.logDebug(StringFormat("sell hedge: %s", Position::getPositionListString(&sellHedgeList)), true);
      
      this.addClosePositions(&buyHedgeList);
      this.addClosePositions(&sellHedgeList);      

      Position::deletePositionList(&buyHedgeList);
      Position::deletePositionList(&sellHedgeList);
   }

   void addClosePositions(CArrayList<PosInfo*> *positions) {
      LoggerFacade logger;
      int count = positions.Count();
      for (int i = 0; i < count; i++) {
         PosInfo *p;
         positions.TryGetValue(i, p);
         logger.logDebug(StringFormat("add position #%d in close position list", p.positionTicket), true);
         Request* req = RequestContainer::createRequest();
         Order::createCloseRequest(req.item, p.positionTicket, p.magicNumber);
         this.orderQueue.add(req);
      }
   }
private:
   // 日付文字列
   string yyyymmdd;
};
