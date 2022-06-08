#include <Generic/Queue.mqh>
#include <Generic/ArrayList.mqh>
#include <Generic/HashMap.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/RequestContainer.mqh>

#include <Custom/v2/Strategy/GridStrategy/Config.mqh>

extern Config *__config;

class GridManager {
public:

   GridManager()
      : gridSize(20) {
   }

   double getTargetGridPrice(ENUM_ENTRY_COMMAND command) {
      double unit = Util::getUnit();
      if (command == ENTRY_COMMAND_NOOP) {
         ExpertRemove();
      }
      double price;
      if (command == ENTRY_COMMAND_BUY) {
         price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      } else {
         price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      }
      double gridPrice = this.getTargetGridPrice(command, 0.0, price);
      return gridPrice;
   }

   bool isGridPriceUsed(ENUM_ORDER_TYPE targetType, double gridPrice, long magicNumber = -1) {
      int posCount = PositionsTotal();
      for (int i = 0; i < posCount; i++) {
         ulong posTicket = PositionGetTicket(i);
         ulong posId = PositionGetInteger(POSITION_IDENTIFIER);
         if (posTicket) {
            if (HistorySelectByPosition(posId)) {
               int dealCount = HistoryDealsTotal();
               for (int j = 0; j < dealCount; j++) {
                  ulong dealTicket = HistoryDealGetTicket(j);
                  if (dealTicket) {
                     ulong orderTicket = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
                     if (HistoryOrderSelect(orderTicket)) {
                        ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
                        double orderPrice = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
                        long orderMagicNumber = HistoryOrderGetInteger(orderTicket, ORDER_MAGIC);
                        string strOrderPrice = DoubleToString(orderPrice, Digits());
                        string strGridPrice = DoubleToString(gridPrice, Digits());
                        if (StringCompare(strOrderPrice, strGridPrice) == 0) {
                           if (targetType == orderType) {
                              if (magicNumber < 0 || magicNumber == orderMagicNumber) {
                                 LOG_DEBUG(StringFormat("grid price %s is already exists in %s position #%d (magic: %d)", strGridPrice, getOrderTypeText(targetType), posTicket, magicNumber));
                                 return true;
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
      int orderCount = OrdersTotal();
      for (int i = 0; i < orderCount; i++) {
         ulong orderTicket = OrderGetTicket(i);
         if (orderTicket) {
            ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
            double orderPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            long orderMagicNumber = OrderGetInteger(ORDER_MAGIC);
            string strOrderPrice = DoubleToString(orderPrice, Digits());
            string strGridPrice = DoubleToString(gridPrice, Digits());
            if (StringCompare(strOrderPrice, strGridPrice) == 0) {
               if (targetType == orderType) {
                  if (magicNumber < 0 || magicNumber == orderMagicNumber) {
                     LOG_DEBUG(StringFormat("grid price %s is already exists in %s order #%d (magic: %d)", strGridPrice, getOrderTypeText(targetType), orderTicket, magicNumber));
                     return true;
                  }
               }
            }
         }
      }
      return false;
   }

   /**
    * リクエストキュー内のすべてのリクエストを使用して発注を行う
    *
    * orderQueue リクエストキュー
    * isGridPriceChecked true: 注文価格がすでに発注済みの場合に発注を行わない false: 常に発注を行う
    */
   void sendOrdersFromQueue(RequestContainer &orderQueue, long magicNumber = -1, bool isGridPriceChecked = true) {
      int reqCount = orderQueue.count();
      for (int i = reqCount - 1; i >= 0; i--) {
         // キューからリクエストを取得する
         Request *req = orderQueue.get(i);

         // リクエストの価格がすでに使われている場合(買い/売りそれぞれ同時に一つまで)はキューから削除し発注せずに終了する
         // ※価格チェックを行う場合のみ
         ENUM_ORDER_TYPE type = req.item.type;
         double price = req.item.price;
         if (isGridPriceChecked && this.isGridPriceUsed(type, price, magicNumber)) {
            orderQueue.remove(i);
            continue;
         }

         // スプレッドが閾値を超えた場合は発注せずに終了する
         long spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
         if (spread > __config.acceptableSpread) {
            LOG_INFO("spread=%d, return");
            continue;
         }

         // 発注処理
         MqlTradeResult result;
         LOG_REQUEST(req);
         bool isSended = OrderSend(req.item, result);
         LOG_RESPONSE(result, isSended);

         // 発注結果確認処理
         // ・成功時はキューから削除。
         // ・失敗した場合は次回の送信まで持ち越し
         // ・致命的エラーの場合はシステム終了
         bool isValid = false;
         if (result.retcode == TRADE_RETCODE_DONE) {
            orderQueue.remove(i);
            isValid = true;
         }
         // 市場が開いてない場合は問題なしなのでパスする
         if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
            isValid = true;
         }
         // 現在値とグリッド価格が近すぎる場合は注文が通らないことが起こり得るのでパスする
         if (result.retcode == TRADE_RETCODE_INVALID_PRICE) {
            orderQueue.remove(i);
            continue;
         }
         if (result.retcode == TRADE_RETCODE_INVALID) {
            orderQueue.remove(i);
            continue;
         }


         // 想定外のエラーのため念のためシステム停止
         if (!isValid) {
            ExpertRemove();
         }
      }
   }

   void setGridSize(double _gridSize) {
      this.gridSize = _gridSize;
   }

private:
   // 使用するグリッドのサイズ(pips)
   double gridSize;

   double getTargetGridPrice(ENUM_ENTRY_COMMAND command, double basePrice, double currentPrice) {
      double unit = Util::getUnit();
      double ret = -1;
      if (command == ENTRY_COMMAND_BUY) {
         double diff = (currentPrice - basePrice) / unit;
         double ratio = diff / this.gridSize;
         ratio = MathCeil(ratio);
         ret = basePrice + ((ratio * this.gridSize) * unit);
      } else {
         double diff = (currentPrice - basePrice) / unit;
         double ratio = diff / this.gridSize;
         ratio = MathFloor(ratio);
         ret = basePrice + ((ratio * this.gridSize) * unit);
      }
      return ret;
   }

   string getOrderTypeText(ENUM_ORDER_TYPE orderType) {
      if (orderType == ORDER_TYPE_BUY_STOP) {
         return "BUY";
      } else {
         return "SELL";
      }
   }

};
