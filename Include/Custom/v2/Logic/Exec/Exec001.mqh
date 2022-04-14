#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Context/Context001.mqh>
#include <Custom/v2/Common/Logger.mqh>

/**
 * ポジション構築を実行する共通処理
 */
class Exec001 {
public:

   static void exec(ENUM_ENTRY_COMMAND command, Context001 &contextMain, Context001 &contextSub, Config001 &config) {

      Logger logger(config.eaName);
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      ZeroMemory(request);
      ZeroMemory(result);

      if (!Util::hasPosition(config.magicNumber)) {

         if (command == ENTRY_COMMAND_BUY) {
            Order::createBuyRequest(request, config.sl, config.tp, config.volume, config.magicNumber);
            logger.logRequest(request);
            bool isSended = OrderSend(request, result);
            logger.logResponse(result);
            Order::checkTradeResult(isSended, result);
         }

         if (command == ENTRY_COMMAND_SELL) {
            Order::createSellRequest(request, config.sl, config.tp, config.volume, config.magicNumber);
            logger.logRequest(request);
            bool isSended = OrderSend(request, result);
            logger.logResponse(result);
            Order::checkTradeResult(isSended, result);
         }
      }
   }
};