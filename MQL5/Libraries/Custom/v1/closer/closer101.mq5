// in Libraries/Custom/v1/closer
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>

#import "Custom/v1/common/common.ex5"
   double getUnit();
   double calcPositionPipsBetweenCurrentAndStop();
   ENUM_POSITION_TYPE getPositionType();
   double getPositionSL();
   void setStop(MqlTradeRequest &request, double newSL, long magicNumber);
   bool checkTradeResult(MqlTradeResult &result);
   void logRequest(string eaName, string header, MqlTradeRequest &request);
   void logResponse(string eaName, string header, MqlTradeResult &result);
#import

string getCloserName() export {
   return "101";
}

/**
 * ポジション保有中の監視処理
 */
void close(
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {

   double pips = calcPositionPipsBetweenCurrentAndStop();
   double newSL = getPositionSL();
   if (pips > config.sl * config.tpRatio) {
      ENUM_POSITION_TYPE type = getPositionType();
      if (type == POSITION_TYPE_BUY) {
         newSL = newSL + (config.sl * getUnit());
      } else {
         newSL = newSL - (config.sl * getUnit());
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