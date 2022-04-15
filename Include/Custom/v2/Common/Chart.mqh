/**
 * チャート関連のロジック集
 */
class Chart {
public:
   
   static bool isUpperBreak(double mainLatest, double mainPrev, double otherLatest, double otherPrev) {
      if (mainLatest >= mainPrev
            && mainLatest > otherLatest
            && mainPrev <= otherPrev) {
         return true;
      }
      return false;
   }
   
   static bool isLowerBreak(double mainLatest, double mainPrev, double otherLatest, double otherPrev) {
      if (mainLatest <= mainPrev
            && mainLatest < otherLatest
            && mainPrev >= otherPrev) {
         return true;
      }
      return false;
   }
   
   /**
    * 価格targetがローソク足のOpen-Closeの範囲に収まっているかどうか判定する
    */
   static bool isInOpenClose(MqlRates &price, double target) {
      double a = price.open;
      double b = price.close;
      bool isIn = false;
      if (a > b) {
         if (a > target && target > b) {
            isIn = true;
         }
      } else {
         if (b > target && target > a) {
            isIn = true;
         }
      }
      return isIn;
   }
};
