// Libraries/Custom/Logics/common.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Generic\HashMap.mqh>
#include <Custom/SlackLib.mqh>

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import

/**
 * EAを特定するためのユニーク番号を生成する
 */
long createMagicNumber(int prefix, int revision) export {
   string magic = StringFormat("%d%d", prefix, revision);
   return StringToInteger(magic);
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

// OK
/**
 * 新規注文のリクエストを生成する
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

void buy(MqlTradeRequest &request, double sl, double volume, long magic) export {
   createNewOrder(request, ORDER_TYPE_BUY, SYMBOL_ASK, SYMBOL_BID, -sl, volume, magic);
}

void sell(MqlTradeRequest &request, double sl, double volume, long magic) export {
   createNewOrder(request, ORDER_TYPE_SELL, SYMBOL_BID, SYMBOL_ASK, +sl, volume, magic);
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

double calcPositionPipsBetweenCurrentAndStop(double unit) export {
   ENUM_POSITION_TYPE type = getPositionType();
   double current = getPositionCurrentPrice();
   double sl = getPositionSL();

   double profit = -1;
   if (type == POSITION_TYPE_BUY) {
      profit = current - sl;
   } else {
      profit = sl - current;
   }
   return profit / unit;
}

double calcPositionPipsBetweenCurrentAndOpen(double unit) export {
   ENUM_POSITION_TYPE type = getPositionType();
   double current = getPositionCurrentPrice();
   double open = getPositionOpenPrice();

   double profit = -1;
   if (type == POSITION_TYPE_BUY) {
      profit = current - open;
   } else {
      profit = open - current;
   }
   return profit / unit;
}


/**
 * 現在保持しているポジションの種別(買い/売り)を取得する
 */
ENUM_POSITION_TYPE getPositionType() export {
   return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
}

/**
 * 決済注文のリクエストを生成する
 */
void close(MqlTradeRequest &request, long magicNumber) export {

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
 * ストップを変更するリクエストを生成する
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
 * 注文送信結果を判定して必要な場合システムを停止する等の処理を行う
 */
void checkTradeResult(MqlTradeResult &result) export {
   bool isAbortRequired = true;
   if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
      isAbortRequired = false;
   }
   if (isAbortRequired) {
      ExpertRemove();
   }
}


/**
 * 通貨ごとのpipsの単位を取得する
 * ex) USDJPY => 1pips = 0.01
 */
double getUnit() export {
   string symbol = Symbol();
   double unit = -1;
   CHashMap<string, double> map;
   map.Add("USDJPY", 0.01);
   map.Add("EURGBP", 0.0001);
   if (map.ContainsKey(symbol)) {
      map.TryGetValue(symbol, unit);
   }
   if (unit < 0) {
      printf("unitの取得に失敗しました!");
      ExpertRemove();
   }
   return unit;
}
