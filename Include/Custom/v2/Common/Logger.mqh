#include <Custom/v2/Common/Request.mqh>

enum ENUM_LOG_LEVEL {
   LOG_LEVEL_DEBUG // 開発中に確認するためのメッセージ
   , LOG_LEVEL_INFO // INFO以上の場合はファイルに記録する
   , LOG_LEVEL_NOTICE // エラーではないが非常に重要な内容を示す。NOTICE以上の場合はSlackに通知を送るようにする等の目的で使用する
   , LOG_LEVEL_ERROR // プログラム的なエラー等が発生した場合等
};

class Logger {
public:
   
   bool debug;
   bool info;
   bool notice;
   bool error;
   
   Logger(string _eaName)
      : eaName(_eaName) {
      debug = true;
      info = true;
      notice = true;
      error = true;   
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

   void logRequest(Request &req, bool force = false) {
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
      this.logWrite(LOG_LEVEL_INFO, text, force);
   }

   void logResponse(MqlTradeResult &result, bool isSended, bool force = false) {
      string text = StringFormat(
         "注文結果: sended=%d, retcode=%d, request_id=%d, deal=#%d, order=#%d"
         , isSended
         , result.retcode
         , result.request_id
         , result.deal
         , result.order
      );
      this.logWrite(LOG_LEVEL_INFO, text, force);
   }

   void logWrite(ENUM_LOG_LEVEL logLevel, string text, bool force = false) {
      
      bool isLogRequired = false;
      if (logLevel == LOG_LEVEL_DEBUG && debug) {
         isLogRequired = true;
      }
      if (logLevel == LOG_LEVEL_INFO && info) {
         isLogRequired = true;
      }
      if (logLevel == LOG_LEVEL_NOTICE && notice) {
         isLogRequired = true;
      }
      if (logLevel == LOG_LEVEL_ERROR && error) {
         isLogRequired = true;
      }                  
      
      if (force) {
         isLogRequired = true;
      }
      
      if (!isLogRequired) {
         return;
      }
      
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
   
   void logAccount(bool force = false) {
      string balance = DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), Digits());
      string free = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), Digits());
      string text = StringFormat("Account Info: balance=%s, free margin: %s", balance, free);
      this.logWrite(LOG_LEVEL_DEBUG, text, force);
   }
   
private:
   string eaName;
   string getDoubleString(double value) {
      return DoubleToString(value, Digits());
   }
};

extern Logger *__LOGGER__;

class LoggerFacade {
public:
   void logRequest(Request &request, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logRequest(request, force);
      }
   }
   void logResponse(MqlTradeResult &result, bool isSended, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logResponse(result, isSended, force);
      }
   }
   void logWrited(ENUM_LOG_LEVEL logLevel, string text, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logWrite(logLevel, text, force);
      }
   }
   void logAccount(bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logAccount(force);
      }
   }
   void logDebug(string text, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logWrite(LOG_LEVEL_DEBUG, text, force);
      }
   }
   void logInfo(string text, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logWrite(LOG_LEVEL_INFO, text, force);
      }
   }
   void logNotice(string text, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logWrite(LOG_LEVEL_NOTICE, text, force);
      }
   }
   void logError(string text, bool force = false) {
      if (__LOGGER__ != NULL) {
         __LOGGER__.logWrite(LOG_LEVEL_ERROR, text, force);
      }
   }         
};
