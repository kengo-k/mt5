#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/DateWrapper.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/Logic/ClosePositions/ClosePositionsBase.mqh>

extern Config *__config;
extern ICheckTrend *__checkTrend;

// ヘッジポジションのクローズロジック実装(※月足想定)
// ・月が切り替わったタイミングで一定以上の黒字ポジションを決済
// ・トレンド転換で残りの全ポジションを決済
class ClosePositions: public ClosePositionsBase {
public:

   ClosePositions(ENUM_TIMEFRAMES _closeTimeframes) {
      this.closeTimeframes = _closeTimeframes;
      this.latestDate = this.getInitialMaxDate();
   }

   void exec() {

      string currentDate = this.getCurrentDate();
      if (this.latestDate == this.getInitialMaxDate()) {
         this.latestDate = currentDate;
      }
      string prevDate = this.latestDate;
      this.latestDate = currentDate;

      int posCount = PositionsTotal();
      if (posCount == 0) {
         this.latestDate = currentDate;
         return;
      }

      PositionSummary summary;
      CArrayList<PosInfo*> buyRed;
      CArrayList<PosInfo*> buyBlack;
      CArrayList<PosInfo*> sellRed;
      CArrayList<PosInfo*> sellBlack;
      Position::summaryPosition(&summary, &buyRed, &buyBlack, &sellRed, &sellBlack, MAGIC_NUMBER_HEDGE);

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

      this.addClosePositions(&buyRed, closeAll);
      this.addClosePositions(&buyBlack, closeAll);
      this.addClosePositions(&sellRed, closeAll);
      this.addClosePositions(&sellBlack, closeAll);

      Position::deletePositionList(&buyRed);
      Position::deletePositionList(&buyBlack);
      Position::deletePositionList(&sellRed);
      Position::deletePositionList(&sellBlack);
   }

   void addClosePositions(CArrayList<PosInfo*> *positions, bool closeAll) {
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

   string getCurrentDate() {

      string ret = "";
      DateWrapper date;
      if (this.closeTimeframes == PERIOD_MN1) {
         ret = date.getYYYYMM();
      } else if (this.closeTimeframes == PERIOD_W1) {
         ret = StringFormat("%d", date.getWeek());
      } else if (this.closeTimeframes == PERIOD_D1) {
         ret = date.getYYYYMMDD();
      } else if (this.closeTimeframes == PERIOD_H1) {
         ret = date.getYYYYMMDDHH();
      } else {
         ExpertRemove();
      }
      return ret;
   }

   string getInitialMaxDate() {
      string ret = "";
      if (this.closeTimeframes == PERIOD_MN1) {
         ret = MAX_YYYYMM;
      } else if (this.closeTimeframes == PERIOD_W1) {
         ret = "9";
      } else if (this.closeTimeframes == PERIOD_D1) {
         ret = MAX_YYYYMMDD;
      } else if (this.closeTimeframes == PERIOD_H1) {
         ret = MAX_YYYYMMDDHH;
      } else {
         ExpertRemove();
      }
      return ret;
   }

private:

   // ポジションクローズのタイミングを指示する期間
   ENUM_TIMEFRAMES closeTimeframes;

   // クローズタイミングを判定するための現在の日付を管理するための文字列
   string latestDate;
};
