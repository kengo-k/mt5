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
      LOG_DEBUG_WITH_ID(StringFormat("  buyRed=%s", Position::getPositionListString(&buyRed)), LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  buyBlack=%s", Position::getPositionListString(&buyBlack)), LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  sellRed=%s", Position::getPositionListString(&sellRed)), LOGID_POSITION);
      LOG_DEBUG_WITH_ID(StringFormat("  sellBlack=%s", Position::getPositionListString(&sellBlack)), LOGID_POSITION);
   }
private:
   long magicNumber;
};
