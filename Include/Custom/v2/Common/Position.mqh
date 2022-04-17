/**
 * ポジション関連のユーティリティメソッド
 */
class Position {
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

   static ENUM_POSITION_TYPE getType() {
      return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   }

   static ulong getTicket() {
      return PositionGetInteger(POSITION_TICKET);
   }

   static double getVolume() {
      return PositionGetDouble(POSITION_VOLUME);
   }

   static double getSL() {
      return PositionGetDouble(POSITION_SL);
   }

   static double getTP() {
      return PositionGetDouble(POSITION_TP);
   }

   static double getOpenPrice() {
      return PositionGetDouble(POSITION_PRICE_OPEN);
   }

   static double getCurrentPrice() {
      return PositionGetDouble(POSITION_PRICE_CURRENT);
   }

};
