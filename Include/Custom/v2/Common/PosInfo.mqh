#include <Generic/Interfaces/IComparer.mqh>

// ポジション関連の情報で一般的に必要と思われるものを抜き出したデータ構造
class PosInfo {
public:
   ulong positionTicket;
   double volume;
   double profitAndSwap;
   double swap;
   long magicNumber;
   ENUM_POSITION_TYPE positionType;
};

class PosInfoComparer : public IComparer<PosInfo*> {
public:
   bool asc;
   PosInfoComparer(bool _asc) {
      this.asc = _asc;
   }
   int Compare(PosInfo* a, PosInfo* b) {
      if (this.asc) {
         return a.profitAndSwap < b.profitAndSwap ? -1 : 1;
      } else {
         return a.profitAndSwap > b.profitAndSwap ? -1 : 1;
      }

   }
};
