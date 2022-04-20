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
            "[INFO] 注文情報 - %s, price: %f, volume: %f, sl: %f, tp: %f, bid: %f, ask: %f, spread: %f"
            , request.symbol
            , request.price
            , request.volume
            , request.sl
            , request.tp
            , SymbolInfoDouble(Symbol(), SYMBOL_BID)
            , SymbolInfoDouble(Symbol(), SYMBOL_ASK)
            , SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID)
         )
      );
   }

   void logResponse(MqlTradeResult &result, bool isSended) {
      printf(
         StringFormat(
            "[INFO] 注文結果: sended?: %d, retcode=%d, request_id=%d, deal=%d, order=%d"
            , isSended
            , result.retcode
            , result.request_id
            , result.deal
            , result.order
         )
      );   
   }

   void logWrite(ENUM_LOG_LEVEL logLevel, string message) {
      printf("[INFO] %s", message);
   }
private:
   string eaName;
};
