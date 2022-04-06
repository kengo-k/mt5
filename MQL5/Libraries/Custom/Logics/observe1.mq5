// Libraries/Custom/Logics/observe1.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/common.ex5"
   double calcPositionPipsBetweenCurrentAndStop(double unit);
   ENUM_POSITION_TYPE getPositionType();
   double getPositionSL();
   void setStop(MqlTradeRequest &request, double newSL, long magicNumber);
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

   double pips = calcPositionPipsBetweenCurrentAndStop(config.unit);
   double newSL = getPositionSL();
   if (pips > config.sl * config.tpRatio) {
      ENUM_POSITION_TYPE type = getPositionType();
      if (type == POSITION_TYPE_BUY) {
         newSL = newSL + (config.sl * config.unit);
      } else {
         newSL = newSL - (config.sl * config.unit);
      }
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      ZeroMemory(request);
      ZeroMemory(result);

      setStop(request, newSL, config.MAGIC_NUMBER);
      logRequest(config.eaName, "[WARN] ストップ更新注文を送信します", request);

      bool isSended = OrderSend(request, result);
      logResponse(config.eaName, "[WARN] 注文送信結果", result);

      if (!isSended) {
         checkTradeResult(result);
      }
   }

}
