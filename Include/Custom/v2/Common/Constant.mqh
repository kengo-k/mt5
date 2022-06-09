typedef void (*INIT_FN)();
typedef double (*GET_CUSTOM_RESULT_FN)();

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
   LOGID_STATE_ENABLED
   , LOGID_STATE_DISABLED
   , LOGID_STATE_NONE
};

enum ENUM_TRADE_MODE {
   TRADE_MODE_NOOP
   , TRADE_MODE_GRID_ONLY
   , TRADE_MODE_HEDGE_ONLY
   , TRADE_MODE_GRID_AND_HEDGE
};

enum ENUM_SWAP_INCLUDE {
   SWAP_INCLUDE_OFF
   , SWAP_INCLUDE_ON
};

enum ENUM_GRID_HEDGE_MODE {
   GRID_HEDGE_MODE_NO_CLOSE
   , GRID_HEDGE_MODE_ONESIDE_CLOSE
   , GRID_HEDGE_MODE_ALL_CLOSE
};

enum ENUM_ENTRY_MODE {
   ENTRY_MODE_BUY_ONLY
   , ENTRY_MODE_SELL_ONLY
   , ENTRY_MODE_BOTH
};

enum ENUM_VOLUME_SETTINGS {
   VOLUME_SETTINGS_STANDARD_MIN
   , VOLUME_SETTINGS_STANDARD_INCREASE
   , VOLUME_SETTINGS_STANDARD_INCREASE_X2
   , VOLUME_SETTINGS_STANDARD_INCREASE_X3
   , VOLUME_SETTINGS_MICRO_MIN
   , VOLUME_SETTINGS_MICRO_INCREASE
   , VOLUME_SETTINGS_MICRO_INCREASE_MID
};

enum ENUM_SPREAD_SETTINGS {
   SPREAD_SETTINGS_NOOP
   , SPREAD_SETTINGS_USDJPY_STD
};
