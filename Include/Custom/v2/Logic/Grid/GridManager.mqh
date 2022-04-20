#include <Generic/Queue.mqh>
#include <Generic/ArrayList.mqh>
#include <Generic/HashMap.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>

class OrderContainer {
public:
   MqlTradeRequest request;
};

class GridManager {
public:

   GridManager(
      double _gridSize
      , string _baseTimeYYYYMM
   ): gridSize(_gridSize)
   , baseTimeYYYYMM(_baseTimeYYYYMM) {

   }

   ~GridManager() {
      printf("destruct!!");
   }

   OrderContainer* createOrderContainer() {
      return new OrderContainer();
   }

   void addOrder(OrderContainer *order) {
      this.orderQueue.Add(order);
   }

   int getOrderCount() {
      return this.orderQueue.Count();
   }

   OrderContainer* getOrder(int index) {
      OrderContainer* order;
      this.orderQueue.TryGetValue(index, order);
      return order;
   }

   bool deleteOrder(int index) {
      if (this.orderQueue.Count() > 0) {
         OrderContainer *order;
         this.orderQueue.TryGetValue(index, order);
         this.orderQueue.RemoveAt(index);
         delete order;
         return true;
      } else {
         return false;
      }
   }

   double getTargetGridPrice(ENUM_ENTRY_COMMAND command) {
      double unit = Util::getUnit();
      if (command == ENTRY_COMMAND_NOOP) {
         ExpertRemove();
      }
      double price;
      double basePrice = this.getGridBasePrice();
      if (command == ENTRY_COMMAND_BUY) {
         price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      } else {
         price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      }
      double gridPrice = this.getTargetGridPrice(command, 0.0, price);
      return gridPrice;
   }

   double getGridBasePrice() {
      datetime baseTime = StringToTime(StringFormat("%s01", this.baseTimeYYYYMM));
      MqlRates prices[];
      ArraySetAsSeries(prices, false);
      CopyRates(Symbol(), PERIOD_MN1, baseTime, 1, prices);
      return prices[0].close;
   }

   void processTransaction(const MqlTradeTransaction &tran, const MqlTradeRequest &request, const MqlTradeResult &result) {
      // 指値注文の送信に成功した場合
      if (tran.type == TRADE_TRANSACTION_ORDER_ADD) {
         if (OrderSelect(tran.order)) {
            double price = OrderGetDouble(ORDER_PRICE_OPEN);
            string strPrice = DoubleToString(price, Digits());
            this.gridOrders.Add(strPrice, tran.order);
         }
      }
      // 指値注文が約定されポジションが建った場合
      if (tran.type == TRADE_TRANSACTION_DEAL_ADD) {
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(tran.deal, DEAL_ENTRY);
         if (entry == DEAL_ENTRY_IN) {
            if (HistoryDealSelect(tran.deal)) {
               ulong orderTicket = HistoryDealGetInteger(tran.deal, DEAL_ORDER);
               if (HistoryOrderSelect(orderTicket)) {
                  ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
                  double price = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
                  string strPrice = DoubleToString(price, Digits());
                  this.gridPositions.Add(strPrice, tran.deal);
                  bool removed = this.gridOrders.Remove(strPrice);
               }
            }
         }
      }
      // 注文が削除された場合※削除は注文が成立されたことによる削除と期限切れによる削除の場合がある
      if (tran.type == TRADE_TRANSACTION_ORDER_DELETE) {
         if (HistoryOrderSelect(tran.order)) {
            ENUM_ORDER_STATE state = (ENUM_ORDER_STATE) HistoryOrderGetInteger(tran.order, ORDER_STATE);
            if (state == ORDER_STATE_EXPIRED) {
               ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) HistoryOrderGetInteger(tran.order, ORDER_TYPE);
               double price = HistoryOrderGetDouble(tran.order, ORDER_PRICE_OPEN);
               string strPrice = DoubleToString(price, Digits());
               bool removed = this.gridOrders.Remove(strPrice);
            }
         }
      }
   }

   bool isGridPriceUsed(double gridPrice) {
      string strGridPrice = DoubleToString(gridPrice, Digits());
      if (
         this.gridOrders.ContainsKey(strGridPrice)
            || this.gridPositions.ContainsKey(strGridPrice)
      ) {
         return true;
      }
      return false;
   }



private:
   CArrayList<OrderContainer*> orderQueue;
   CHashMap<string, ulong> gridOrders;
   CHashMap<string, ulong> gridPositions;
   // 使用するグリッドのサイズ(pips)
   double gridSize;
   // グリッド作成の基準地点となる日付
   string baseTimeYYYYMM;

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

};