#include <Custom/v2/Common/Util.mqh>

/**
 * ポジション操作に関連するロジック
 */
class Order {

public:

   static void createBuyRequest(MqlTradeRequest &request, double sl, double tp, double volume, long magic) {
      Order::createNewOrder(request, ORDER_TYPE_BUY, SYMBOL_ASK, SYMBOL_BID, sl, tp, volume, magic);
   }

   static void createSellRequest(MqlTradeRequest &request, double sl, double tp, double volume, long magic) {
      Order::createNewOrder(request, ORDER_TYPE_SELL, SYMBOL_BID, SYMBOL_ASK, sl, tp, volume, magic);
   }

   static void createCloseRequest(MqlTradeRequest &request, long magicNumber) {

      ulong ticketNo = Util::getPositionTicket();
      double volume = Util::getPositionVolume();
      ENUM_POSITION_TYPE entryType = Util::getPositionType();

      // ポジション種別に応じて対応する決済の種別を設定 ex)ポジションが買いなら決済は売り
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

   static void createSlTpRequest(MqlTradeRequest &request, double newSL, long magicNumber) {

      ulong ticketNo = Util::getPositionTicket();
      double tp = Util::getPositionTP();

      request.action = TRADE_ACTION_SLTP;
      request.position = ticketNo;
      request.symbol = Symbol();
      request.sl = newSL;
      request.tp = tp;
      request.magic = magicNumber;
   }


   static void checkTradeResult(bool isSended, MqlTradeResult &result) {

      if (isSended) {
         return;
      }

      bool isValid = false;
      if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
         isValid = true;
      }

      if (!isValid) {
         ExpertRemove();
      }
   }

private:

   /**
    * 新規注文のリクエストを生成する共通処理
    */
   static void createNewOrder(
      MqlTradeRequest &request
      , ENUM_ORDER_TYPE type // BUY/SELL
      , ENUM_SYMBOL_INFO_DOUBLE targetSymbolInfo // 注文のASK/BID
      , ENUM_SYMBOL_INFO_DOUBLE oppositeSymbolInfo // 反対側のASK/BID ※ストップの算出に使う
      , double sl
      , double tp
      , double volume
      , long magicNumber
   ) {
      double unit = Util::getUnit();
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

      if (sl > 0) {
         double adjust = 0;
         if (type == ORDER_TYPE_BUY) {
            adjust = - (sl * unit);
         } else {
            adjust = + (sl * unit);
         }
         request.sl = oppositePrice + adjust;
      }
      if (tp > 0) {
         double adjust = 0;
         if (type == ORDER_TYPE_BUY) {
            adjust = + (tp * unit);
         } else {
            adjust = - (tp * unit);
         }
         request.tp = oppositePrice + adjust;
      }

      request.deviation = 3; // 許容スリッページ
      request.expiration = ORDER_TIME_DAY; // 有効期限
      request.comment = ""; // 任意のコメント
      request.magic = magicNumber;
   }
};
