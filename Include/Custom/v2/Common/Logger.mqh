#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Request.mqh>

class Logger {
public:

   bool debug;
   bool info;
   bool notice;
   bool error;

   Logger(string _eaName, ENUM_LOG_LEVEL level)
      : eaName(_eaName) {
      this.setLogLevel(level);
   }

   void setLogLevel(ENUM_LOG_LEVEL level) {
      debug = false;
      info = false;
      notice = false;
      error = false;
      if (level <= LOG_LEVEL_DEBUG) {
         debug = true;
      }
      if (level <= LOG_LEVEL_INFO) {
         info = true;
      }
      if (level <= LOG_LEVEL_NOTICE) {
         notice = true;
      }
      if (level <= LOG_LEVEL_ERROR) {
         error = true;
      }
   }

   void logRequest(Request &req) {
      string text = "";
      MqlTradeRequest request = req.item;
      if (request.action == TRADE_ACTION_DEAL) {
         if (request.position > 0) {
            text = StringFormat(
               "注文(決済)#%d: symbol=%s, position=#%d, magic=%d"
               , req.requestId
               , Symbol()
               , request.position
               , request.magic
            );
         } else {
            text = StringFormat(
               "注文(成行)#%d: symbol=%s, price=%f, volume=%.3f, sl=%f, tp=%f, bid=%f, ask=%f, spread=%f, magic=%d"
               , req.requestId
               , Symbol()
               , getDoubleString(request.price)
               , request.volume
               , getDoubleString(request.sl)
               , getDoubleString(request.tp)
               , SymbolInfoDouble(Symbol(), SYMBOL_BID)
               , SymbolInfoDouble(Symbol(), SYMBOL_ASK)
               , SymbolInfoDouble(Symbol(), SYMBOL_ASK) - SymbolInfoDouble(Symbol(), SYMBOL_BID)
               , request.magic
            );
         }
      } else if (request.action == TRADE_ACTION_PENDING) {
         text = StringFormat(
            "注文(指値)#%d: symbol=%s, price=%s, volume=%.3f, sl=%s, tp=%s, magic=%d"
            , req.requestId
            , Symbol()
            , getDoubleString(request.price)
            , request.volume
            , getDoubleString(request.sl)
            , getDoubleString(request.tp)
            , req.item.magic
         );
      } else if (request.action == TRADE_ACTION_SLTP) {
         text = StringFormat(
            "注文(SLTP)#%d: symbol=%s, position=#%d, sl=%f, tp=%f, magic=%d"
            , req.requestId
            , Symbol()
            , request.position
            , getDoubleString(request.sl)
            , getDoubleString(request.tp)
            , request.magic
         );
      } else if (request.action == TRADE_ACTION_REMOVE) {
         text = StringFormat(
            "注文(キャンセル)#%d: symbol=%s, order: #%d, magic=%d"
            , req.requestId
            , Symbol()
            , request.order
            , request.magic
         );
      }
      this.logWrite(LOG_LEVEL_INFO, text);
   }

   void logResponse(MqlTradeResult &result, bool isSended) {
      string text = StringFormat(
         "注文結果: sended=%d, retcode=%d, request_id=%d, deal=#%d, order=#%d"
         , isSended
         , result.retcode
         , result.request_id
         , result.deal
         , result.order
      );
      this.logWrite(LOG_LEVEL_INFO, text);
   }

   void logWrite(ENUM_LOG_LEVEL logLevel, string text) {
      string message;
      if (logLevel == LOG_LEVEL_DEBUG) {
         message = "★ [DEBUG] %s";
      } else if(logLevel == LOG_LEVEL_INFO) {
         message = "★★★ [INFO] %s ";
      } else if(logLevel == LOG_LEVEL_NOTICE) {
         message = "★★★ [NOTICE] %s";
      } else {
         message = "★★★★★ [ERROR] %s";
      }
      message = StringFormat(message, text);
      printf(message);
   }

   void logAccount() {
      string balance = DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), Digits());
      string free = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), Digits());
      string text = StringFormat("Account Info: balance=%s, free margin: %s", balance, free);
      this.logWrite(LOG_LEVEL_DEBUG, text);
   }

private:
   string eaName;
   string getDoubleString(double value) {
      return DoubleToString(value, Digits());
   }
};

extern Logger *__LOGGER__;

#define LOG_DEBUG_WITH_ID(text, logId) \
   if (__LOGGER__ != NULL) {\
      bool enabled = false;\
      if (logId.state == LOGID_STATE_ENABLED) {\
         enabled = true;\
      } else if (logId.state == LOGID_STATE_DISABLED) {\
         enabled = false;\
      } else {\
         if (__LOGGER__.debug) {\
            enabled = true;\
         }\
      }\
      if (enabled) {\
         __LOGGER__.logWrite(LOG_LEVEL_DEBUG, text);\
      }\
   }\

#define LOG_DEBUG(text) LOG_DEBUG_WITH_ID(text, LOGID_DEFAULT)

#define LOG_INFO_WITH_ID(text, logId) \
   if (__LOGGER__ != NULL) {\
      bool enabled = false;\
      if (logId.state == LOGID_STATE_ENABLED) {\
         enabled = true;\
      } else if (logId.state == LOGID_STATE_DISABLED) {\
         enabled = false;\
      } else {\
         if (__LOGGER__.info) {\
            enabled = true;\
         }\
      }\
      if (enabled) {\
         __LOGGER__.logWrite(LOG_LEVEL_INFO, text);\
      }\
   }\

#define LOG_INFO(text) LOG_INFO_WITH_ID(text, LOGID_DEFAULT)

#define LOG_ERROR_WITH_ID(text, logId) \
   if (__LOGGER__ != NULL) {\
      bool enabled = false;\
      if (logId.state == LOGID_STATE_ENABLED) {\
         enabled = true;\
      } else if (logId.state == LOGID_STATE_DISABLED) {\
         enabled = false;\
      } else {\
         if (__LOGGER__.error) {\
            enabled = true;\
         }\
      }\
      if (enabled) {\
         __LOGGER__.logWrite(LOG_LEVEL_ERROR, text);\
      }\
   }\

#define LOG_ERROR(text) LOG_ERROR_WITH_ID(text, LOGID_DEFAULT)

#define LOG_REQUEST_WITH_ID(req, logId) \
   if (__LOGGER__ != NULL) {\
      bool enabled = false;\
      if (logId.state == LOGID_STATE_ENABLED) {\
         enabled = true;\
      } else if (logId.state == LOGID_STATE_DISABLED) {\
         enabled = false;\
      } else {\
         if (__LOGGER__.info) {\
            enabled = true;\
         }\
      }\
      if (enabled) {\
         __LOGGER__.logRequest(req);\
      }\
   }\

#define LOG_REQUEST(req) LOG_REQUEST_WITH_ID(req, LOGID_DEFAULT)

#define LOG_RESPONSE_WITH_ID(result, isSended, logId) \
   if (__LOGGER__ != NULL) {\
      bool enabled = false;\
      if (logId.state == LOGID_STATE_ENABLED) {\
         enabled = true;\
      } else if (logId.state == LOGID_STATE_DISABLED) {\
         enabled = false;\
      } else {\
         if (__LOGGER__.info) {\
            enabled = true;\
         }\
      }\
      if (enabled) {\
         __LOGGER__.logResponse(result, isSended);\
      }\
   }\

#define LOG_RESPONSE(result, isSended) LOG_RESPONSE_WITH_ID(result, isSended, LOGID_DEFAULT)
