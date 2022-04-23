#include <Generic/Queue.mqh>
#include <Generic/ArrayList.mqh>
#include <Generic/HashMap.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>

class GridManager {
public:

   GridManager(double _gridSize)
      : gridSize(_gridSize) {
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

   bool isGridPriceUsed(ENUM_ORDER_TYPE targetType, double gridPrice) {
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
                        string strOrderPrice = DoubleToString(orderPrice, Digits());
                        string strGridPrice = DoubleToString(gridPrice, Digits());
                        if (StringCompare(strOrderPrice, strGridPrice) == 0) {
                           if (targetType == orderType) {
                              return true;
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
            string strOrderPrice = DoubleToString(orderPrice, Digits());
            string strGridPrice = DoubleToString(gridPrice, Digits());
            if (StringCompare(strOrderPrice, strGridPrice) == 0) {
               if (targetType == orderType) {
                  return true;
               }
            }
         }
      }
      return false;
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

};
