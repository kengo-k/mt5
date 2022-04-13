enum ENUM_LOG_LEVEL {
   LOG_LEVEL_INFO,
   LOG_LEVEL_NOTICE, // NOTICE以上の場合はSlackに通知を送るようにする
   LOG_LEVEL_ERROR
};

class Logger {
public:
   Logger(string _eaName)
      : eaName(_eaName) {}

   void logRequest(MqlTradeRequest &request) {
      // 後で書く
   }

   void logResponse(MqlTradeResult &result) {
      // 後で書く
   }

   void logWrite(ENUM_LOG_LEVEL logLevel, string message) {
      printf("[INFO] %s", message);
   }
private:
   string eaName;
};
