#include <Generic/HashMap.mqh>
#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>

// 一定期間毎にポジションの利益/損失の推移をCSVファイルに記録する
class PositionRecorder : public IObserver {
public:

   PositionRecorder(int _fileHandle) {
      this.fileHandle = _fileHandle;
   }

   void exec() {
      CArrayList<double> positionValues;
      CHashMap<long, PositionSummary*> map;
      CArrayList<long> keyList;
      keyList.Add(MAGIC_NUMBER_MAIN);
      keyList.Add(MAGIC_NUMBER_HEDGE);
      int posCount = PositionsTotal();
      for (int i = 0; i < posCount; i++) {
         ulong posTicket = PositionGetTicket(i);
         if (posTicket) {

            PosInfo p;
            Position::setPosInfo(&p);
            if (!keyList.Contains(p.magicNumber)) {
               keyList.Add(p.magicNumber);
            }

            PositionSummary *summary;
            map.TryGetValue(p.magicNumber, summary);
            if (summary == NULL) {
               summary = new PositionSummary();
               map.TrySetValue(p.magicNumber, summary);
            }
            if (p.positionType == POSITION_TYPE_BUY) {
               summary.buy += p.profitAndSwap;
               summary.buyCount++;
            } else {
               summary.sell += p.profitAndSwap;
               summary.sellCount++;
            }
         }
      }

      int keyCount = keyList.Count();
      for (int i = 0 ; i < keyCount; i++) {
         long magicNumber;
         keyList.TryGetValue(i, magicNumber);
         PositionSummary *summary;
         map.TryGetValue(magicNumber, summary);
         if (summary != NULL) {
            positionValues.Add(summary.buyCount);
            positionValues.Add(summary.buy);
            positionValues.Add(summary.sellCount);
            positionValues.Add(summary.sell);
            delete summary;
         } else {
            positionValues.Add(0);
            positionValues.Add(0);
            positionValues.Add(0);
            positionValues.Add(0);
         }
      }

      int columnCount = positionValues.Count();
      string row = StringFormat("%s, ", Util::getCurrentDateString());
      for (int i = 0; i < columnCount; i++) {
         double value;
         positionValues.TryGetValue(i, value);
         StringAdd(row, StringFormat("%d", (int)value));
         if (i != columnCount - 1) {
            StringAdd(row, ",");
         }
      }
      FileWrite(this.fileHandle, row);
   }

private:
   int fileHandle;
};
