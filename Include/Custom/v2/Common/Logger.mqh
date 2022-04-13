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
      printf(
         StringFormat(
            "[INFO] 注文情報 - %s, price: %f, volume: %f, sl: %f, tp: %f"
            , request.symbol
            , request.price
            , request.volume
            , request.sl
            , request.tp
         )
      );
   }

   void logResponse(MqlTradeResult &result) {
   }

   void logWrite(ENUM_LOG_LEVEL logLevel, string message) {
      printf("[INFO] %s", message);
   }
private:
   string eaName;
};
