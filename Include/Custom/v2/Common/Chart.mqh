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
};
