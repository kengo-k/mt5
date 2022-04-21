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
      if (command == ENTRY_COMMAND_BUY) {
         price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      } else {
         price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      }
      double gridPrice = this.getTargetGridPrice(command, 0.0, price);
      return gridPrice;
   }

   bool isGridPriceUsed(ENUM_ENTRY_COMMAND command, double gridPrice) {
      printf("grid %f, price is used?", gridPrice);
      printf("----- check duplicate in position -----");
      int posCount = PositionsTotal();
      printf("position count: %d", posCount);
      for (int i = 0; i < posCount; i++) {
         ulong posTicket = PositionGetTicket(i);
         ulong posId = PositionGetInteger(POSITION_IDENTIFIER);
         if (posTicket) {
            if (HistorySelectByPosition(posId)) {
               int dealCount = HistoryDealsTotal();
               printf("deal count: %d", dealCount);
               for (int j = 0; j < dealCount; j++) {
                  ulong dealTicket = HistoryDealGetTicket(j);
                  printf("deal #%d", dealTicket);
                  if (dealTicket) {
                     ulong orderTicket = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
                     printf("order #%d from deal #%d", orderTicket, dealTicket);
                     if (HistoryOrderSelect(orderTicket)) {
                        double orderPrice = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
                        string strOrderPrice = DoubleToString(orderPrice, Digits());
                        string strGridPrice = DoubleToString(gridPrice, Digits());
                        printf("order price: %s, grid price: %s", strOrderPrice, strGridPrice);
                        if (StringCompare(strOrderPrice, strGridPrice) == 0) {
                           return true;
                        }
                     }
                  }
               }
            }
         }
      }
      printf("----- check duplicate in order -----");
      int orderCount = OrdersTotal();
      printf("order count: %d", orderCount);
      for (int i = 0; i < orderCount; i++) {
         ulong orderTicket = OrderGetTicket(i);
         if (orderTicket) {
            double orderPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            string strOrderPrice = DoubleToString(orderPrice, Digits());
            string strGridPrice = DoubleToString(gridPrice, Digits());            
            printf("order price: %s, grid price: %s", strOrderPrice, strGridPrice);
            if (StringCompare(strOrderPrice, strGridPrice) == 0) {
               return true;
            }
         }
      }
      return false;
   }



private:
   CArrayList<OrderContainer*> orderQueue;
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
