// in Libraries/Custom/v1/common
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Generic\HashMap.mqh>
#include <Custom/v1/SlackLib.mqh>

// slack関連定数
const string API_PATH = "https://slack.com/api/chat.postMessage";
const string API_TOKEN = "xoxb-1575963846754-2351585442598-1sXQfrbugJpksBPHmtDJQcQQ";
const int timeout = 3000;
const bool TestMode = true;

// このストラテジグループのマジックナンバーに使用する共通のプレフィクス番号
const int MAGICNUMBER_PREFIX = 1;

/**
 * slackのチャンネルにメッセージを投稿する
 * 
 * バックテスト中の場合は大量のメッセージを投稿してしまうため
 * モードが有効の場合のみ実行する。
 */
int notifySlack(string message, string channel) export
{
   if (TestMode) {
      Print(message);
      return 0;   
   } else {
      string requestHeaders;
      string responseHeaders;
      char request[];
      char response[];
      datetime current = TimeCurrent();
      string messageWithTime = StringFormat("%s [%s]", message, TimeToString(current, TIME_DATE | TIME_MINUTES));
      string reqString = StringFormat("token=%s&channel=%s&text=%s"
         , API_TOKEN
         , channel
         , messageWithTime
      );
      StringToCharArray(reqString, request, 0, -1, CP_UTF8);
      int retCode = WebRequest("POST"
         , API_PATH
         , requestHeaders
         , timeout
         , request
         , response
         , responseHeaders
      );
      return retCode;
   }
}

/**
 * EAを特定するためのユニーク番号を生成する
 */
long createMagicNumber(string pattern1, string pattern2) export {
   string magic = StringFormat("%03d%s%s", MAGICNUMBER_PREFIX, pattern1, pattern2);
   return StringToInteger(magic);
}

/**
 * 通貨ごとのpipsの単位を取得する
 * ex) USDJPY => 1pips = 0.01
 */
double getUnit() export {
   string symbol = Symbol();
   double unit = -1;
   CHashMap<string, double> map;
   // 新しい通貨ペアを取り扱う場合はここに追記すること
   map.Add("USDJPY", 0.01);
   map.Add("EURGBP", 0.0001);
   if (map.ContainsKey(symbol)) {
      map.TryGetValue(symbol, unit);
   }
   return unit;
}

string getPeriodName(ENUM_TIMEFRAMES period) export {
   string periodName = "";
   if (period == PERIOD_CURRENT) {
      period = Period();
   }
   switch (period) {
      case PERIOD_M5:
         periodName = "M5";
         break;
      case PERIOD_M15:
         periodName = "M15";
         break;
      case PERIOD_H1:
         periodName = "H1";
         break;
      case PERIOD_H4:
         periodName = "H4";
         break;
      case PERIOD_D1:
         periodName = "D1";
         break;
      case PERIOD_W1:
         periodName = "W1";
         break;
      case PERIOD_MN1:
         periodName = "MN1";
         break;                                             
   }
   if (StringLen(periodName) == 0) {
      ExpertRemove();
   }
   return periodName;
}

/**
 * 注文のリクエスト情報をログに出力
 */
void logRequest(string eaName, string header, MqlTradeRequest &request) export {
   NOTIFY_MESSAGE(
      eaName,
      StringFormat(
         "%s - %s, price: %f, volume: %f, stop: %f, fillMode: %d"
         , header
         , request.symbol
         , request.price
         , request.volume
         , request.sl
         , request.type_filling
      )
   );
}

/**
 * 注文のレスポンス情報をログに出力
 */
void logResponse(string eaName, string header, MqlTradeResult &result) export {
   NOTIFY_MESSAGE(
      eaName,
      StringFormat(
         "%s - request_id: %d, retcode: %d, retcode_external: %d, deal: %d, order: %d, "
         , header
         , result.request_id
         , result.retcode
         , result.retcode_external
         , result.deal
         , result.order
      )
   );
}

/**
 * 注文の送信が正常に行われなかった場合の処理
 * 注文送信結果を判定して必要な場合システムを停止する等の処理を行う
 */
bool checkTradeResult(MqlTradeResult &result) export {
   // falseが返された場合はシステムを停止する
   bool isValid = false;
   if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
      isValid = true;
   }
   if (!isValid) {
      ExpertRemove();
   }
   return isValid;
}

/**
 * 買い注文のリクエストを生成する
 */
void buy(MqlTradeRequest &request, double sl, double volume, long magic) export {
   createNewOrder(request, ORDER_TYPE_BUY, SYMBOL_ASK, SYMBOL_BID, -sl, volume, magic);
}

/**
 * 売り注文のリクエストを生成する
 */
void sell(MqlTradeRequest &request, double sl, double volume, long magic) export {
   createNewOrder(request, ORDER_TYPE_SELL, SYMBOL_BID, SYMBOL_ASK, +sl, volume, magic);
}

/**
 * 決済注文のリクエストを生成する
 */
void fix(MqlTradeRequest &request, long magicNumber) export {

   ulong ticketNo = getPositionTicket();
   double volume = getPositionVolume();
   ENUM_POSITION_TYPE entryType = getPositionType();

   // ポジション種別に応じて決済の種別を設定
   ENUM_ORDER_TYPE closeType = ORDER_TYPE_BUY;
   ENUM_SYMBOL_INFO_DOUBLE symbolInfo = SYMBOL_BID;
   if (entryType == POSITION_TYPE_BUY) {
      symbolInfo = SYMBOL_ASK;
      closeType = ORDER_TYPE_SELL;
   }

   request.action = TRADE_ACTION_DEAL;
   request.position = ticketNo;
   request.symbol = Symbol();
   request.volume = volume;
   request.deviation = 3;
   request.magic = magicNumber;
   request.price = SymbolInfoDouble(Symbol(), symbolInfo);
   request.type = closeType;
   request.type_filling = ORDER_FILLING_IOC;
}

/**
 * ストップ変更注文のリクエストを生成する
 */
void setStop(MqlTradeRequest &request, double newSL, long magicNumber) export {

   ulong ticketNo = getPositionTicket();
   double tp = getPositionTP();

   request.action = TRADE_ACTION_SLTP;
   request.position = ticketNo;
   request.symbol = Symbol();
   request.sl = newSL;
   request.tp = tp;
   request.magic = magicNumber;
}

/**
 * 現在保持しているポジションの種別(買い/売り)を取得する
 */
ENUM_POSITION_TYPE getPositionType() export {
   return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
}

/**
 * 現在保持しているポジションのチケット番号を取得する。
 */
ulong getPositionTicket() export {
   return PositionGetInteger(POSITION_TICKET);
}

/**
 * 現在保持しているポジションのボリュームを取得する
 */
double getPositionVolume() export {
   return PositionGetDouble(POSITION_VOLUME);
}

double getPositionSL() export {
   return PositionGetDouble(POSITION_SL);
}

double getPositionTP() export {
   return PositionGetDouble(POSITION_TP);
}

double getPositionOpenPrice() export {
   return PositionGetDouble(POSITION_PRICE_OPEN);
}

double getPositionCurrentPrice() export {
   return PositionGetDouble(POSITION_PRICE_CURRENT);
}

double calcPositionPipsBetweenCurrentAndStop() export {
   ENUM_POSITION_TYPE type = getPositionType();
   double current = getPositionCurrentPrice();
   double sl = getPositionSL();

   double profit = -1;
   if (type == POSITION_TYPE_BUY) {
      profit = current - sl;
   } else {
      profit = sl - current;
   }
   return profit / getUnit();
}

double calcPositionPipsBetweenCurrentAndOpen() export {
   ENUM_POSITION_TYPE type = getPositionType();
   double current = getPositionCurrentPrice();
   double open = getPositionOpenPrice();

   double profit = -1;
   if (type == POSITION_TYPE_BUY) {
      profit = current - open;
   } else {
      profit = open - current;
   }
   return profit / getUnit();
}

bool isStopMoved() export {
   
   bool moved = false;

   ENUM_POSITION_TYPE type = getPositionType();
   double sl = getPositionSL();
   double open = getPositionOpenPrice();
   
   if (type == POSITION_TYPE_BUY) {
      if (sl > open) {
         moved = true;
      }
   } else {
      if (sl < open) {
         moved = true;
      }
   }
   
   return moved;
}

/**
 * 新規注文のリクエストを生成する共通処理
 */
void createNewOrder(
   MqlTradeRequest &request
   , ENUM_ORDER_TYPE type // BUY/SELL
   , ENUM_SYMBOL_INFO_DOUBLE targetSymbolInfo // 注文のASK/BID
   , ENUM_SYMBOL_INFO_DOUBLE oppositeSymbolInfo // 反対側のASK/BID ※ストップの算出に使う
   , double sl
   , double volume
   , long magicNumber
) {

   double targetPrice = SymbolInfoDouble(Symbol(), targetSymbolInfo);
   double oppositePrice = SymbolInfoDouble(Symbol(), oppositeSymbolInfo);

   request.action = TRADE_ACTION_DEAL;
   request.type = type;
   request.symbol = Symbol();
   request.volume = volume;
   request.price = targetPrice;

   // 指定したボリュームを調達できない場合にどのように振る舞うかのモード
   // キャンセルする/可能な量のみでポジションを立てる/etc
   request.type_filling = ORDER_FILLING_IOC;

   // ストップを設定する
   // ※利益確定の指値はとりあえず入れない方針でやってみる
   // (ストップを動かしてトレーリングする)
   request.sl = oppositePrice + sl;

   request.deviation = 3; // 許容スリッページ
   request.expiration = ORDER_TIME_DAY; // 有効期限
   request.comment = ""; // 任意のコメント
   request.magic = magicNumber;
}

bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal) export {
   if (new_macd >= old_macd
         && new_macd > new_signal
         && old_macd <= old_signal) {
      return true;
   }
   return false;
}

bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal) export {
   if (new_macd <= old_macd
         && new_macd < new_signal
         && old_macd >= old_signal) {
      return true;
   }
   return false;
}
