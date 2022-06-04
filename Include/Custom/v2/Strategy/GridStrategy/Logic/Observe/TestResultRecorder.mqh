#include <Generic/HashMap.mqh>
#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>

#include <Custom/v2/Strategy/GridStrategy/Config.mqh>

extern Config *__config;

// 一定期間毎にポジションの利益/損失の推移をCSVファイルに記録する
class TestResultRecorder : public IObserver {
public:

   TestResultRecorder(int _fileHandle) {
      this.fileHandle = _fileHandle;

      // 一行目をコメント行とする。コメント行はパラメータを記録するために使用する
      CArrayList<string> commentList;
      commentList.Add(StringFormat("tp=%d", (int)__config.tp));
      commentList.Add(StringFormat("totalHedgeTp=%d", (int)__config.totalHedgeTp));
      commentList.Add(StringFormat("createOrderTimeframe=%d", __config.createOrderTimeframe));
      commentList.Add(StringFormat("hedgeDirectionTimeframe=%d", __config.hedgeDirectionTimeframe));
      commentList.Add(StringFormat("orderMaPeriod=%d", __config.orderMaPeriod));
      commentList.Add(StringFormat("orderLongMaPeriod=%d", __config.orderLongMaPeriod));
      commentList.Add(StringFormat("hedgeMaPeriod=%d", __config.hedgeMaPeriod));
      commentList.Add(StringFormat("hedgeLongMaPeriod=%d", __config.hedgeLongMaPeriod));
      commentList.Add(StringFormat("orderGridSize=%d", (int)__config.orderGridSize));
      commentList.Add(StringFormat("hedgeGridSize=%d", (int)__config.hedgeGridSize));
      commentList.Add(StringFormat("useGridTrade=%d", __config.useGridTrade));
      commentList.Add(StringFormat("useGridHedgeTrade=%d", __config.useGridHedgeTrade));
      commentList.Add(StringFormat("gridHedgeMode=%d", __config.gridHedgeMode));
      string commentLine = Util::join(&commentList, ",  ");
      FileWrite(this.fileHandle, StringFormat("#%s", commentLine));
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
         StringAdd(row, ",");
      }
      int balance = (int) AccountInfoDouble(ACCOUNT_BALANCE);
      int marginFree = (int) AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      StringAdd(row, StringFormat("%d,%d", balance, marginFree));
      FileWrite(this.fileHandle, row);
   }

private:
   int fileHandle;
};