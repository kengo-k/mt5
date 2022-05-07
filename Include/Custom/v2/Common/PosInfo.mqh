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
