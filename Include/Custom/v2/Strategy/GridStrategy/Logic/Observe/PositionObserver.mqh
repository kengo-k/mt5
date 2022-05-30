#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>

// ポジション詳細をログに記録する
class PositionObserver : public IObserver {
public:

   PositionObserver(long _magicNumber)
      : magicNumber(_magicNumber) {}

   void exec() {
      PosInfoComparer asc(true);
      PosInfoComparer desc(false);

      PositionSummary summary;
      CArrayList<PosInfo*> buyRed;
      CArrayList<PosInfo*> buyBlack;
      CArrayList<PosInfo*> sellRed;
      CArrayList<PosInfo*> sellBlack;
      Position::summaryPosition(&summary, &buyRed, &buyBlack, &sellRed, &sellBlack, this.magicNumber);

      buyRed.Sort(&desc);
      buyBlack.Sort(&asc);
      sellRed.Sort(&desc);
      sellBlack.Sort(&asc);

      LOG_DEBUG_WITH_ID(StringFormat("---------- position summary (magic number=%d) ----------", this.magicNumber), LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  profit: buy(%d)=%d, sell(%d)=%d", summary.buyCount, (int) summary.buy, summary.sellCount, (int) summary.sell), LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  buyRed=%s", Position::getPositionListString(&buyRed)), LOGID_POSITION_DETAIL);
      LOG_DEBUG_WITH_ID(StringFormat("  buyBlack=%s", Position::getPositionListString(&buyBlack)), LOGID_POSITION_DETAIL);
      LOG_DEBUG_WITH_ID(StringFormat("  sellRed=%s", Position::getPositionListString(&sellRed)), LOGID_POSITION_DETAIL);
      LOG_DEBUG_WITH_ID(StringFormat("  sellBlack=%s", Position::getPositionListString(&sellBlack)), LOGID_POSITION_DETAIL);

      Position::deletePositionList(&buyRed);
      Position::deletePositionList(&buyBlack);
      Position::deletePositionList(&sellRed);
      Position::deletePositionList(&sellBlack);

      // position count
      if (summary.totalCount > this.maxTotalPositionCount) {
         this.maxTotalPositionCount = summary.totalCount;
      }

      if (summary.buyCount > this.maxBuyPositionCount) {
         this.maxBuyPositionCount = summary.buyCount;
      }

      if (summary.sellCount > this.maxSellPositionCount) {
         this.maxSellPositionCount = summary.sellCount;
      }


      // profit
      if (summary.total > this.maxTotalProfit) {
         this.maxTotalProfit = summary.total;
      }

      if (summary.buyBlack > this.maxBuyProfit) {
         this.maxBuyProfit = summary.buyBlack;
      }

      if (summary.sellBlack > this.maxSellProfit) {
         this.maxSellProfit = summary.sellBlack;
      }

      // loss
      if (summary.total < this.maxTotalLoss) {
         this.maxTotalLoss = summary.total;
      }

      if (summary.buyRed < this.maxBuyLoss) {
         this.maxBuyLoss = summary.buyRed;
      }

      if (summary.sellRed < this.maxSellLoss) {
         this.maxSellLoss = summary.sellRed;
      }
   }

   void logTotalReport() {
      LOG_DEBUG_WITH_ID(StringFormat("---------- total position report (magic number=%d) ----------", this.magicNumber), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max position count total: %d", this.maxTotalPositionCount), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max position count buy: %d", this.maxBuyPositionCount), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max position count sell: %d", this.maxSellPositionCount), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max profit total: %f", this.maxTotalProfit), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max profit buy: %f", this.maxBuyProfit), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max profit sell: %f", this.maxSellProfit), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max loss total: %f", this.maxTotalLoss), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max loss buy: %f", this.maxBuyLoss), LOGID_POSITION_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max loss sell: %f", this.maxSellLoss), LOGID_POSITION_TOTAL);
   }

   // 以下レポート要用変数
   long maxTotalPositionCount;
   long maxBuyPositionCount;
   long maxSellPositionCount;

   double maxTotalProfit;
   double maxBuyProfit;
   double maxSellProfit;

   double maxTotalLoss;
   double maxBuyLoss;
   double maxSellLoss;

private:
   long magicNumber;
};
