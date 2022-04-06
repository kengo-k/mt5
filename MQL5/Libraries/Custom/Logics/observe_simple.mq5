// Libraries/Custom/Logics/observe1.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import
#include <Custom/SlackLib.mqh>

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/common.ex5"
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
   SimpleMACDContext &contextMain,
   SimpleMACDContext &contextSub,
   SimpleMACDConfig &config
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
