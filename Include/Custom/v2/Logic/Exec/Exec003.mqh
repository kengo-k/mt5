#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Position.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Config/Config003.mqh>
#include <Custom/v2/Context/Context002.mqh>
#include <Custom/v2/Common/Logger.mqh>

/**
 * ポジション構築を実行する共通処理
 */
class Exec003 {
public:

   static void exec(ENUM_ENTRY_COMMAND command, Context002 &contextMain, Context002 &contextSub, Config003 &config) {

      Logger logger(config.eaName);
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      ZeroMemory(request);
      ZeroMemory(result);
      
      if (!Position::hasPosition(config.magicNumber)) {

         if (command == ENTRY_COMMAND_BUY) {
            Order::createBuyRequest(request, config.initialSL, -1, config.volume, config.magicNumber);

            logger.logRequest(request);
            bool isSended = OrderSend(request, result);
            logger.logResponse(result);
            Order::checkTradeResult(isSended, result);
         }

         if (command == ENTRY_COMMAND_SELL) {
            Order::createSellRequest(request, config.initialSL, -1, config.volume, config.magicNumber);
            logger.logRequest(request);
            bool isSended = OrderSend(request, result);
            logger.logResponse(result);
            Order::checkTradeResult(isSended, result);
         }
      }
   }
};
