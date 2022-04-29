#include <Generic/HashMap.mqh>

/**
 * 各種ユーティリティメソッド
 */
class Util {
public:

   static datetime getCurrentDate() {
      datetime t = TimeCurrent();
      t = toDate(t);
      return t;
   }

   static datetime addDay(datetime t, int day) {
      t = t + (60 * 60 * 24 * day);
      return t;
   }

   static datetime addSec(datetime t, int sec) {
      t = t + sec;
      return t;
   }

   static int getDiffDay(datetime d1, datetime d2) {
      long diffSec = d1 - d2;
      int oneDay = 60 * 60 * 24;
      int diffDay = (int) MathFloor(diffSec / oneDay);
      return diffDay;
   }

   static bool isSameMonth(datetime d1, datetime d2) {
      MqlDateTime t1, t2;
      TimeToStruct(d1, t1);
      TimeToStruct(d2, t2);
      return t1.year == t2.year && t1.mon == t2.mon;
   }

   static string getCurrentMonth() {
      MqlDateTime t;
      datetime current = TimeCurrent();
      TimeToStruct(current, t);
      return StringFormat("%d%d", t.year, t.mon);
   }

   static datetime toDate(datetime t) {
      string s = TimeToString(t, TIME_DATE);
      return StringToTime(s);
   }

   static double getUnit() {
      string symbol = Symbol();
      double unit = -1;
      CHashMap<string, double> map;
      // 新しい通貨ペアを取り扱う場合はここに追記すること
      map.Add("USDJPY", 0.01);
      map.Add("EURGBP", 0.0001);
      map.Add("AUDNZD", 0.0001);
      if (map.ContainsKey(symbol)) {
         map.TryGetValue(symbol, unit);
      }
      return unit;
   }

   static string getPeriodName(ENUM_TIMEFRAMES period) {
      string periodName = "";
      if (period == PERIOD_CURRENT) {
         period = Period();
      }
      switch (period) {
         case PERIOD_M5:
            periodName = "M5";
            break;
         case PERIOD_M15:
            periodName = "M15";
            break;
         case PERIOD_H1:
            periodName = "H1";
            break;
         case PERIOD_H4:
            periodName = "H4";
            break;
         case PERIOD_D1:
            periodName = "D1";
            break;
         case PERIOD_W1:
            periodName = "W1";
            break;
         case PERIOD_MN1:
            periodName = "MN1";
            break;
      }
      if (StringLen(periodName) == 0) {
         ExpertRemove();
      }
      return periodName;
   }

   static void logProfit(const MqlTradeTransaction &tran, const MqlTradeRequest &request, const MqlTradeResult &result) {

      /*
         TRADE_TRANSACTION_ORDER_ADD: 0
         TRADE_TRANSACTION_ORDER_UPDATE: 1
         TRADE_TRANSACTION_ORDER_DELETE: 2
         TRADE_TRANSACTION_DEAL_ADD: 6
         TRADE_TRANSACTION_DEAL_UPDATE: 7
         TRADE_TRANSACTION_DEAL_DELETE: 8
         TRADE_TRANSACTION_HISTORY_ADD: 3
         TRADE_TRANSACTION_HISTORY_UPDATE: 4
         TRADE_TRANSACTION_HISTORY_DELETE: 5
         TRADE_TRANSACTION_POSITION: 9
         TRADE_TRANSACTION_REQUEST: 10
      */

      /*
         DEAL_ENTRY_IN: 0
         DEAL_ENTRY_OUT: 1
         DEAL_ENTRY_INOUT: 2
         DEAL_ENTRY_OUT_BY: 3
      */

      if (tran.type == TRADE_TRANSACTION_DEAL_ADD) {
         if (HistoryDealSelect(tran.deal)) {
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(tran.deal, DEAL_ENTRY);
            if (entry == DEAL_ENTRY_OUT) {
               double profit = HistoryDealGetDouble(tran.deal, DEAL_PROFIT);
               printf("deal %d: profit=%f", tran.deal, profit);
            }
         }
      }
   }

   static double calcWinRatio() {
      return TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES) * 100;
   }

};
