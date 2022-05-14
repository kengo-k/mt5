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

      LOG_DEBUG_WITH_ID(StringFormat("count: buy=%d, sell=%d", summary.buyCount, summary.sellCount), LOGID_POSITION);
      LOG_DEBUG_WITH_ID("buyRed: " + Position::getPositionListString(&buyRed), LOGID_POSITION);
      LOG_DEBUG_WITH_ID("buyBlack: " + Position::getPositionListString(&buyBlack), LOGID_POSITION);
      LOG_DEBUG_WITH_ID("sellRed: " + Position::getPositionListString(&sellRed), LOGID_POSITION);
      LOG_DEBUG_WITH_ID("sellBlack: " + Position::getPositionListString(&sellBlack), LOGID_POSITION);
   }
private:
   long magicNumber;
};
