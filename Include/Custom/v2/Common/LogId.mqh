#include <Custom/v2/Common/Constant.mqh>

// 個々のログの出力ON/OFFを切り替えるためのID
class LogId {
public:
   LogId(ENUM_LOGID_STATE _state): state(_state) {}
   LogId(): state(LOGID_STATE_NONE) {}
   ENUM_LOGID_STATE state;
   void set(ENUM_LOGID_STATE _state) {
      this.state = _state;
   }
};

LogId __LOGID_DEFAULT(LOGID_STATE_NONE);
LogId *LOGID_DEFAULT = &__LOGID_DEFAULT;

LogId __LOGID_ENABLED(LOGID_STATE_ENABLED);
LogId *LOGID_ENABLED = &__LOGID_ENABLED;

LogId __LOGID_DISABLED(LOGID_STATE_DISABLED);
LogId *LOGID_DISABLED = &__LOGID_DISABLED;

LogId __LOGID_ACCOUNT;
LogId *LOGID_ACCOUNT = &__LOGID_ACCOUNT;

LogId __LOGID_POSITION;
LogId *LOGID_POSITION = &__LOGID_POSITION;

LogId __LOGID_CLOSE;
LogId *LOGID_CLOSE = &__LOGID_CLOSE;
