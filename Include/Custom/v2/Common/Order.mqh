#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/PosInfo.mqh>

/**
 * ポジション操作に関連するロジック
 */
class Order {

public:

   static void createBuyRequest(MqlTradeRequest &request, double sl, double tp, double volume, long magic, bool usePips = true) {
      Order::createNewOrder(request, ORDER_TYPE_BUY, SYMBOL_ASK, SYMBOL_BID, sl, tp, volume, magic, usePips);
   }

   static void createSellRequest(MqlTradeRequest &request, double sl, double tp, double volume, long magic, bool usePips = true) {
      Order::createNewOrder(request, ORDER_TYPE_SELL, SYMBOL_BID, SYMBOL_ASK, sl, tp, volume, magic, usePips);
   }

   static void createCloseRequest(MqlTradeRequest &request, long positionTicket, long magicNumber) {

      if (!PositionSelectByTicket(positionTicket)) {
         ExpertRemove();
      }
      PosInfo p;
      Position::setPosInfo(&p);
      double volume = p.volume;
      ENUM_POSITION_TYPE entryType = p.positionType;

      // ポジション種別に応じて対応する決済の種別を設定 ex)ポジションが買いなら決済は売り
      ENUM_ORDER_TYPE closeType = ORDER_TYPE_BUY;
      ENUM_SYMBOL_INFO_DOUBLE symbolInfo = SYMBOL_BID;
      if (entryType == POSITION_TYPE_BUY) {
         symbolInfo = SYMBOL_ASK;
         closeType = ORDER_TYPE_SELL;
      }

      request.action = TRADE_ACTION_DEAL;
      request.position = positionTicket;
      request.symbol = Symbol();
      request.volume = volume;
      request.deviation = 3;
      request.magic = magicNumber;
      request.price = SymbolInfoDouble(Symbol(), symbolInfo);
      request.type = closeType;
      request.type_filling = ORDER_FILLING_IOC;
   }

   static void createSlTpRequest(MqlTradeRequest &request, long positionTicket, double sl, double tp, long magicNumber) {

      request.action = TRADE_ACTION_SLTP;
      request.position = positionTicket;
      request.symbol = Symbol();
      if (sl > 0) {
         request.sl = sl;
      }
      if (tp > 0) {
         request.tp = tp;
      }
      request.magic = magicNumber;
   }

   static void createLimitRequest(ENUM_ENTRY_COMMAND command, MqlTradeRequest &request, double price, double volume, double sl, double tp, long magicNumber) {

      if (command == ENTRY_COMMAND_NOOP) {
         return;
      }

      double unit = Util::getUnit();
      ENUM_ORDER_TYPE orderType;
      if (command == ENTRY_COMMAND_BUY) {
         orderType = ORDER_TYPE_BUY_STOP;
         if (sl > 0) {
            request.sl = price - (sl * unit);
         }
         if (tp > 0) {
            request.tp = price + (tp * unit);
         }
      } else {
         orderType = ORDER_TYPE_SELL_STOP;
         if (sl > 0) {
            request.sl = price + (sl * unit);
         }
         if (tp > 0) {
            request.tp = price - (tp * unit);
         }
      }

      request.action = TRADE_ACTION_PENDING;
      request.price = price;
      request.type = orderType;
      request.symbol = Symbol();
      request.volume = volume;
      request.deviation = 3;
      request.magic = magicNumber;
   }

   static void createCancelRequest(MqlTradeRequest &request, long orderTicket) {
      request.action = TRADE_ACTION_REMOVE;
      request.order = orderTicket;
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
      , bool usePips
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
         if (usePips) {
            double adjust = 0;
            if (type == ORDER_TYPE_BUY) {
               adjust = - (sl * unit);
            } else {
               adjust = + (sl * unit);
            }
            request.sl = oppositePrice + adjust;
         } else {
            request.sl = sl;
         }
      }
      if (tp > 0) {
         if (usePips) {
            double adjust = 0;
            if (type == ORDER_TYPE_BUY) {
               adjust = + (tp * unit);
            } else {
               adjust = - (tp * unit);
            }
            request.tp = oppositePrice + adjust;
         } else {
            request.tp = tp;
         }
      }

      request.deviation = 3; // 許容スリッページ
      request.expiration = ORDER_TIME_DAY; // 有効期限
      request.comment = ""; // 任意のコメント
      request.magic = magicNumber;
   }
};
