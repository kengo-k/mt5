#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Chart.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Config/Config003.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Logger.mqh>

/**
 * 決済処理
 */
class Close001 {
public:
   static void close(Context002 &contextMain, Context002 &contextSub, Config003 &config) {
      Logger logger(config.eaName);
      ENUM_POSITION_TYPE type = Position::getType();
      double unit = Util::getUnit();
      double base = 0;
      double newSL = 0;
      double current = Position::getCurrentPrice();
      bool fixed = Position::isProfitFixed();
      if (fixed) {
         base = Position::getSL();
      } else {
         base = Position::getOpenPrice();
      }
      bool isUpdateRequired = false;
      if (type == POSITION_TYPE_BUY) {
         double diff = (current - base) / unit;
         if (diff > config.nextSL) {
            newSL = current - (config.trail * unit);
            isUpdateRequired = true;
         }
      } else {
         double diff = (base - current) / unit;
         if (diff > config.nextSL) {
            newSL = current + (config.trail * unit);
            isUpdateRequired = true;
         }
      }
      if (isUpdateRequired) {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};
         ZeroMemory(request);
         ZeroMemory(result);      
         Order::createSlTpRequest(request, newSL, config.magicNumber);
         logger.logRequest(request);
         bool isSended = OrderSend(request, result);
         logger.logResponse(result);
         Order::checkTradeResult(isSended, result);         
      }
   }
};
