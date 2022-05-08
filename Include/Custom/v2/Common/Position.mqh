#include <Generic/ArrayList.mqh>
#include <Custom/v2/Common/PosInfo.mqh>
#include <Custom/v2/Common/PositionSummary.mqh>

// ポジション関連のメソッド集
class Position {
public:

   static void setPosInfo(PosInfo *posInfo) {
      posInfo.magicNumber = PositionGetInteger(POSITION_MAGIC);
      posInfo.positionTicket = PositionGetInteger(POSITION_TICKET);
      posInfo.positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
      posInfo.volume = PositionGetDouble(POSITION_VOLUME);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double swap = PositionGetDouble(POSITION_SWAP);
      posInfo.profitAndSwap = profit + swap;
      posInfo.swap = swap;
   }

   static void setPosInfo(PosInfo *posInfo, ulong positionTicket) {
      if (PositionSelectByTicket(positionTicket)) {
         Position::setPosInfo(posInfo);
      }
   }

   static string getPositionListString(CArrayList<PosInfo*> *list) {
      string str = "[";
      int count = list.Count();
      for (int i = 0; i < count; i++) {
         PosInfo *p;
         list.TryGetValue(i, p);
         if (i != 0) {
            StringAdd(str, ", ");
         }
         string ps = DoubleToString(p.profitAndSwap, Digits());
         string s = DoubleToString(p.swap, Digits());
         StringAdd(str, StringFormat("%s(%s)#%d", ps, s, p.positionTicket));
      }
      str = str + "]";
      return str;
   }

   static void deletePositionList(CArrayList<PosInfo*> *list) {
      int count = list.Count();
      for (int i = 0; i < count; i++) {
         PosInfo *p;
         list.TryGetValue(i, p);
         delete p;
      }
   }

   static void summaryPosition(PositionSummary &summary, long magicNumber) {

      int buyCount = 0;
      int sellCount = 0;

      double red = 0;
      double black = 0;
      double buy = 0;
      double buyRed = 0;
      double buyBlack = 0;

      double sell = 0;
      double sellRed = 0;
      double sellBlack = 0;

      int posCount = PositionsTotal();
      for (int i = 0; i < posCount; i++) {
         ulong posTicket = PositionGetTicket(i);
         if (posTicket) {
            long posMagicNumber = PositionGetInteger(POSITION_MAGIC);
            if (magicNumber != posMagicNumber) {
               continue;
            }
            double profit = PositionGetDouble(POSITION_PROFIT);
            double swap = PositionGetDouble(POSITION_SWAP);
            double profitAndSwap = profit + swap;
            if (profitAndSwap < 0) {
               red = red + profitAndSwap;
            } else {
               black = black + profitAndSwap;
            }
            ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
            if (positionType == POSITION_TYPE_BUY) {
               if (profitAndSwap < 0) {
                  buyRed = buyRed + profitAndSwap;
               } else {
                  buyBlack = buyBlack + profitAndSwap;
               }
               buy = buy + profitAndSwap;
               buyCount++;
            } else {
               if (profitAndSwap < 0) {
                  sellRed = sellRed + profitAndSwap;
               } else {
                  sellBlack = sellBlack + profitAndSwap;
               }
               sell = sell + profitAndSwap;
               sellCount++;
            }
         }
      }

      summary.totalCount = buyCount + sellCount;
      summary.buyCount = buyCount;
      summary.sellCount = sellCount;

      summary.total = buy + sell;
      summary.red = red;
      summary.black = black;

      summary.buy = buy;
      summary.buyRed = buyRed;
      summary.buyBlack = buyBlack;

      summary.sell = sell;
      summary.sellRed = sellRed;
      summary.sellBlack = sellBlack;
   }
};
