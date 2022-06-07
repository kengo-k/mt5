#include <Generic/HashMap.mqh>
#include <Generic/ArrayList.mqh>

/**
 * 各種ユーティリティメソッド
 */
class Util {
public:

   static string getAgentName() {
      string path = TerminalInfoString(TERMINAL_DATA_PATH);
      string strSep = "\\";
      string split_result[];
      ushort sep = StringGetCharacter(strSep, 0);
      StringSplit(path, sep, split_result);
      int len = ArraySize(split_result);
      string agentName = split_result[len - 1];
      return agentName;
   }

   static string createUniqueFileName(string prefix, string extension) {
      int fileCount = 1;
      string fileName;
      string agentName = Util::getAgentName();
      long handle = FileFindFirst(StringFormat("%s-%s-*", prefix, agentName), fileName, FILE_COMMON);
      if (handle != INVALID_HANDLE) {
         fileCount++;
         while(FileFindNext(handle, fileName)) {
            fileCount++;
         }
      }
      return StringFormat("%s-%s-%d.%s", prefix, agentName, fileCount, extension);
   }

   static string join(CArrayList<string> *strList, string sep) {
      string ret = "";
      int count = strList.Count();
      for (int i = 0; i < count; i++) {
         string s;
         strList.TryGetValue(i, s);
         StringAdd(ret, s);
         if (i != count - 1) {
            StringAdd(ret, sep);
         }
      }
      return ret;
   }

   static datetime getCurrentDate() {
      datetime t = TimeCurrent();
      t = toDate(t);
      return t;
   }

   static string getCurrentDateString() {
      datetime now = Util::getCurrentDate();
      MqlDateTime t;
      TimeToStruct(now, t);
      return StringFormat("%d/%d/%d", t.year, t.mon, t.day);
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
      map.Add("USDJPYmicro", 0.01);
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

   static datetime getJpTime(datetime day = 0) {
      MqlDateTime cjtm;
      day = day == 0 ? TimeCurrent() : day; // 対象サーバ時間
      datetime time_summer = 21600; // ６時間
      datetime time_winter = 25200; // ７時間
      int target_dow = 0; // 日曜日
      int start_st_n = 2; // 夏時間開始3月第2週
      int end_st_n = 1; // 夏時間終了11月第1週
      TimeToStruct(day, cjtm); // 構造体の変数に変換
      string year = (string)cjtm.year; // 対象年
      // 対象年の3月1日と11月1日の曜日
      TimeToStruct(StringToTime(year + ".03.01"), cjtm);
      int fdo_mar = cjtm.day_of_week;
      TimeToStruct(StringToTime(year + ".11.01"), cjtm);
      int fdo_nov = cjtm.day_of_week;
      // 3月第2日曜日
      int start_st_day = (target_dow < fdo_mar ? target_dow + 7 : target_dow)
                       - fdo_mar + 7 * start_st_n - 6;
      // 11月第1日曜日
      int end_st_day = (target_dow < fdo_nov ? target_dow + 7 : target_dow)
                     - fdo_nov + 7 * end_st_n - 6;
      // 対象年の夏時間開始日と終了日を確定
      datetime start_st = StringToTime(year + ".03." + (string)start_st_day);
      datetime end_st = StringToTime(year + ".11." + (string)end_st_day);
      // 日本時間を返す
      return day += start_st <= day && day <= end_st
                  ? time_summer : time_winter;
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
