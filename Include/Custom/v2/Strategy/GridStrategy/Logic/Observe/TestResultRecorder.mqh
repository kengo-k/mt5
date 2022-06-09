#include <Generic/HashMap.mqh>
#include <Generic/ArrayList.mqh>

#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/VolumeCalculator.mqh>
#include <Custom/v2/Common/HedgeTpCalculator.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/TimeframeSwitchHandler.mqh>

#include <Custom/v2/Strategy/GridStrategy/Config.mqh>

extern Config *__config;
extern IVolumeCalculator *__volumeCalculator;
extern IHedgeTpCalculator *__hedgeTpCalculator;

// 一定期間毎にポジションの利益/損失の推移をCSVファイルに記録する
class TestResultRecorder : public IObserver {
public:

   TestResultRecorder(int _fileHandle) {
      this.fileHandle = _fileHandle;
      this.handler.set(PERIOD_MN1);
      // 一行目をコメント行とする。コメント行はパラメータを記録するために使用する
      CArrayList<string> commentList;
      commentList.Add(StringFormat("GRID_TP=%d", (int)__config.tp));
      commentList.Add(StringFormat("HEDGE_TP=%d/%s(%s)", __config.hedgeTpSettings, EnumToString(__config.hedgeTpSettings), __hedgeTpCalculator.toString()));
      commentList.Add(StringFormat("VOLUME=%d/%s(%s)", __config.volumeSettings, EnumToString(__config.volumeSettings), __volumeCalculator.toString()));
      commentList.Add(StringFormat("SPREAD=%d", __config.maxSpread));
      commentList.Add(StringFormat("INCLUDE_SWAP=%d", __config.isIncludeSwap));
      commentList.Add(StringFormat("BUYABLE=%d", __config.buyable));
      commentList.Add(StringFormat("SELLABLE=%d", __config.sellable));
      commentList.Add(StringFormat("USE_GRID=%d", __config.useGridTrade));
      commentList.Add(StringFormat("USE_HEDGE=%d", __config.useGridHedgeTrade));
      commentList.Add(StringFormat("HEDGE_MODE=%d/%s", __config.gridHedgeMode, EnumToString(__config.gridHedgeMode)));
      commentList.Add(StringFormat("ORDER_GRID_SIZE=%d", (int)__config.orderGridSize));
      commentList.Add(StringFormat("HEDGE_GRID_SIZE=%d", (int)__config.hedgeGridSize));
      commentList.Add(StringFormat("ORDER_TIMEFRAME=%s", StringSubstr(EnumToString(__config.createOrderTimeframe), 7)));
      commentList.Add(StringFormat("ORDER_MA_PERIOD=%d", __config.orderMaPeriod));
      commentList.Add(StringFormat("ORDER_LONG_MA_PERIOD=%d", __config.orderLongMaPeriod));
      commentList.Add(StringFormat("TREND_TIMEFRAME=%s", StringSubstr(EnumToString(__config.hedgeDirectionTimeframe), 7)));
      commentList.Add(StringFormat("TREND_MA_PERIOD=%d", __config.hedgeMaPeriod));
      commentList.Add(StringFormat("TREND_LONG_MA_PERIOD=%d", __config.hedgeLongMaPeriod));
      int headerCount = commentList.Count();
      for (int i = 0; i < headerCount; i++) {
         string header;
         commentList.TryGetValue(i, header);
         FileWrite(this.fileHandle, StringFormat("#%s", header));
      }

   }

   void exec() {
      this.handler.update();
      if (!this.handler.isSwitched()) {
         return;
      }
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
            double profit = p.profit;
            if (__config.isIncludeSwap) {
               profit = p.profitAndSwap;
            }
            if (p.positionType == POSITION_TYPE_BUY) {
               summary.buy += profit;
               summary.buyCount++;
            } else {
               summary.sell += profit;
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
   TimeframeSwitchHandler handler;
};
