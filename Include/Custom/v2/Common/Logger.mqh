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
      if (request.action == TRADE_ACTION_DEAL) {
         if (request.position > 0) {
            printf(
               StringFormat(
                  "★★★ [INFO] 注文(決済) - %s, position: #%d"
                  , Symbol()
                  , request.position
               )
            );
         } else {
            printf(
               StringFormat(
                  "★★★ [INFO] 注文(成行) - %s, price: %f, volume: %f, sl: %f, tp: %f, bid: %f, ask: %f, spread: %f"
                  , Symbol()
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
      } else if (request.action == TRADE_ACTION_PENDING) {
         printf(
            StringFormat(
               "★★★ [INFO] 注文(指値) - %s, price: %f, volume: %f, sl: %f, tp: %f, bid: %f, ask: %f, spread: %f"
               , Symbol()
               , request.price
               , request.volume
               , request.sl
               , request.tp
               , SymbolInfoDouble(Symbol(), SYMBOL_BID)
               , SymbolInfoDouble(Symbol(), SYMBOL_ASK)
               , SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID)
            )
         );
      } else if (request.action == TRADE_ACTION_SLTP) {
         printf(
            StringFormat(
               "★★★ [INFO] 注文(SLTP) - %s, position: #%d, sl: %f, tp: %f, bid: %f, ask: %f, spread: %f"
               , Symbol()
               , request.position
               , request.sl
               , request.tp
               , SymbolInfoDouble(Symbol(), SYMBOL_BID)
               , SymbolInfoDouble(Symbol(), SYMBOL_ASK)
               , SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID)
            )
         );
      } else if (request.action == TRADE_ACTION_REMOVE) {
         printf(
            StringFormat(
               "★★★ [INFO] 注文(キャンセル) - %s, order: #%d"
               , Symbol()
               , request.order
            )
         );
      }
   }

   void logResponse(MqlTradeResult &result, bool isSended) {
      printf(
         StringFormat(
            "★★★ [INFO] 注文結果: sended?: %d, retcode=%d, request_id=%d, deal=%d, order=%d"
            , isSended
            , result.retcode
            , result.request_id
            , result.deal
            , result.order
         )
      );
   }

   void logWrite(ENUM_LOG_LEVEL logLevel, string message) {
      printf("★★★ [INFO] %s", message);
   }
private:
   string eaName;
};

extern Logger *__LOGGER__;

class LoggerFacade {
public:
   void logRequest(MqlTradeRequest &request) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logRequest(request);
      }
   }
   void logResponse(MqlTradeResult &result, bool isSended) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logResponse(result, isSended);
      }
   }
   void logWrite(ENUM_LOG_LEVEL logLevel, string message) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logWrite(logLevel, message);
      }
   }
};
