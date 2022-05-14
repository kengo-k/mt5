typedef void (*INIT_FN)();

const long MAGIC_NUMBER_MAIN = 1;
const long MAGIC_NUMBER_HEDGE = 2;

const string MAX_YYYYMM = "999912";
const string MAX_YYYYMMDD = "99991231";
const string MAX_YYYYMMDDHH = "9999123123";

//条件判定の結果としてポジションを建てる/建てないかを示す定数
enum ENUM_ENTRY_COMMAND {
   ENTRY_COMMAND_BUY
   ,ENTRY_COMMAND_SELL
   ,ENTRY_COMMAND_NOOP
};

enum ENUM_LOG_LEVEL {
   LOG_LEVEL_DEBUG // 開発中に確認するためのメッセージ
   , LOG_LEVEL_INFO // INFO以上の場合はファイルに記録する
   , LOG_LEVEL_NOTICE // エラーではないが非常に重要な内容を示す。NOTICE以上の場合はSlackに通知を送るようにする等の目的で使用する
   , LOG_LEVEL_ERROR // プログラム的なエラー等が発生した場合等
};

enum ENUM_LOGID_STATE {
   LOGID_STATE_ENABLED,
   LOGID_STATE_DISABLED,
   LOGID_STATE_NONE
};
