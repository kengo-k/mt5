// in Libraries/Custom/v1/observer
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>
#include <Custom/v1/SlackLib.mqh>

#import "Custom/v1/common/common.ex5"
   int notifySlack(string message, string channel);
   void close(MqlTradeRequest &request, long magicNumber);
   double calcPositionPipsBetweenCurrentAndOpen(double unit);
   void checkTradeResult(MqlTradeResult &result);
   void logRequest(string eaName, string header, MqlTradeRequest &request);
   void logResponse(string eaName, string header, MqlTradeResult &result);
#import

/**
 * ポジション保有中の監視処理
 */
void observe(
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {

   double pips = calcPositionPipsBetweenCurrentAndOpen(config.unit);
   if (pips >= config.tp) {
      POST_MESSAGE(config.eaName, StringFormat("pips: %f, tp: %f", pips, config.tp));
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      ZeroMemory(request);
      ZeroMemory(result);
      
      close(request, config.MAGIC_NUMBER);
      logRequest(config.eaName, "[WARN] 決済注文送信します", request);
      
      bool isSended = OrderSend(request, result);
      logResponse(config.eaName, "[WARN] 注文送信結果", result);

      if (!isSended) {
         checkTradeResult(result);
      }
   }
}
