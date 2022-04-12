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
   double calcPositionPipsBetweenCurrentAndOpen();
   bool isStopMoved();
   ENUM_POSITION_TYPE getPositionType();
   double getPositionSL();
   double getPositionOpenPrice();
   void setStop(MqlTradeRequest &request, double newSL, long magicNumber);
   bool checkTradeResult(MqlTradeResult &result);
   void logRequest(string eaName, string header, MqlTradeRequest &request);
   void logResponse(string eaName, string header, MqlTradeResult &result);
#import

string getCloserName() export {
   return "111";
}

/**
 * ポジション保有中の監視処理
 *
 * 
 */
void close(
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {
   
   // ストップ更新するかどうか
   bool isStopUpdateRequired = false;
   
   double unit = getUnit();
   ENUM_POSITION_TYPE type = getPositionType();
   
   // (更新が可能であれば)新しいストップの値。初期値として現在のストップ
   double newSL = getPositionSL();
   double open = getPositionOpenPrice();
   
   // ストップが一度でも更新されているかどうかを判定
   // 一度でも動いた=利益確定済み状態となる
   // 利益確定状態後はトレーリングするためロジックを切り替える
   if (isStopMoved()) {
      double pips = calcPositionPipsBetweenCurrentAndStop();
      if (pips - config.trailValue > 1) {
         isStopUpdateRequired = true;
         if (type == POSITION_TYPE_BUY) {
            newSL = newSL + ((pips - config.trailValue) * unit);
         } else {
            //printf("current SL: %f, pips: %f", newSL, pips);
            newSL = newSL - ((pips - config.trailValue) * unit);
            //printf("newSL: %f", newSL);
         }
      }
   } else {
      // 現在の利益もしくは損失 (pips)
      double pips = calcPositionPipsBetweenCurrentAndOpen();   
      if (pips > config.firstProfitTarget) {
         isStopUpdateRequired = true;
         if (type == POSITION_TYPE_BUY) {
            newSL = open + (config.firstProfitValue * unit);
         } else {
            newSL = open - (config.firstProfitValue * unit);
         }
      }
   }
  
   if (isStopUpdateRequired) {
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
