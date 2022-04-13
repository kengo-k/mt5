#include <Generic/HashMap.mqh>

/**
 * 各種ユーティリティメソッド
 */
class Util {
public:

   static bool hasPosition(long magicNumber) {
      int posCount = 0;
      for (int i = 0; i < PositionsTotal(); i++) {
         string symbol = PositionGetSymbol(i);
         if (StringLen(symbol) > 0) {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if (magic == magicNumber) {
               posCount++;
            }
         }
      }
      if (posCount == 0) {
         return false;
      } else if (posCount == 1) {
         return true;
      } else {
         // ポジションは同時に複数持たない方針であるため
         // ポジション数が1でも0でもない場合は何らかの不具合であるため即座に処理を終了させる
         printf("ポジション数が不正です");
         ExpertRemove();
         return false;
      }
   }

   static ENUM_POSITION_TYPE getPositionType() {
      return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   }

   static ulong getPositionTicket() {
      return PositionGetInteger(POSITION_TICKET);
   }

   static double getPositionVolume() {
      return PositionGetDouble(POSITION_VOLUME);
   }

   static double getPositionSL() {
      return PositionGetDouble(POSITION_SL);
   }

   static double getPositionTP() {
      return PositionGetDouble(POSITION_TP);
   }

   static double getPositionOpenPrice() {
      return PositionGetDouble(POSITION_PRICE_OPEN);
   }

   static double getPositionCurrentPrice() {
      return PositionGetDouble(POSITION_PRICE_CURRENT);
   }

   static double getUnit() {
      string symbol = Symbol();
      double unit = -1;
      CHashMap<string, double> map;
      // 新しい通貨ペアを取り扱う場合はここに追記すること
      map.Add("USDJPY", 0.01);
      map.Add("EURGBP", 0.0001);
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

   static bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal) {
      if (new_macd >= old_macd
            && new_macd > new_signal
            && old_macd <= old_signal) {
         return true;
      }
      return false;
   }

   static bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal) {
      if (new_macd <= old_macd
            && new_macd < new_signal
            && old_macd >= old_signal) {
         return true;
      }
      return false;
   }

};
