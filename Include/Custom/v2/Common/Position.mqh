#include <Generic/ArrayList.mqh>
#include <Custom/v2/Common/PosInfo.mqh>

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
};
