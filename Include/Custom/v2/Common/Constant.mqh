const long MAGIC_NUMBER_MAIN = 1;
const long MAGIC_NUMBER_HEDGE = 2;

const string MAX_YYYYMM = "999912";
const string MAX_YYYYMMDD = "99991231";

//条件判定の結果としてポジションを建てる/建てないかを示す定数
enum ENUM_ENTRY_COMMAND {
   ENTRY_COMMAND_BUY
   ,ENTRY_COMMAND_SELL
   ,ENTRY_COMMAND_NOOP
};
