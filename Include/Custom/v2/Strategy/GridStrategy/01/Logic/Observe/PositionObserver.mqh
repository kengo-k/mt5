#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IObserve.mqh>

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

      LOG_DEBUG_WITH_ID("---------- Position Summary ----------", LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  profit: buy=%d, sell=%d, count: buy=%d, sell=%d", (int) summary.buy, (int) summary.sell, summary.buyCount, summary.sellCount), LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  buyRed=%s", Position::getPositionListString(&buyRed)), LOGID_POSITION_DETAIL);
      LOG_DEBUG_WITH_ID(StringFormat("  buyBlack=%s", Position::getPositionListString(&buyBlack)), LOGID_POSITION_DETAIL);
      LOG_DEBUG_WITH_ID(StringFormat("  sellRed=%s", Position::getPositionListString(&sellRed)), LOGID_POSITION_DETAIL);
      LOG_DEBUG_WITH_ID(StringFormat("  sellBlack=%s", Position::getPositionListString(&sellBlack)), LOGID_POSITION_DETAIL);

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
