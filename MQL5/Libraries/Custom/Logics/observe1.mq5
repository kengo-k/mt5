// Libraries/Custom/Logics/observe1.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/common.ex5"
   double calcPositionPipsBetweenCurrentAndStop();
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
   SimpleMACDContext &contextMain, 
   SimpleMACDContext &contextSub, 
   SimpleMACDConfig &config
) export {
   
   double pips = calcPositionPipsBetweenCurrentAndStop();
   double newSL = getPositionSL();
   if (pips > config.sl * config.tpRatio) {
      ENUM_POSITION_TYPE type = getPositionType();
      if (type == POSITION_TYPE_BUY) {
         newSL = newSL + config.sl;
      } else {
         newSL = newSL - config.sl;
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
   
      /*
         double current = -1;
         double open = -1;
         double sl = -1;
         bool isCurrentSuccess = GET_CURRENT_PRICE(current);
         bool isOpenSuccess = GET_OPEN_PRICE(open);
         bool isSLSuccess = GET_SL_PRICE(sl);
         if (isCurrentSuccess && isOpenSuccess && isSLSuccess) {
            double nextSL = -1;
            int sign = 0;
            bool isNextSLSuccess = calcNextSL(open, current, nextSL, sign);
            if (isNextSLSuccess) {
               bool isUpdatedRequired = false;
               if (sign == 1) {
                  if (nextSL > sl + (sign * 0.01)) {
                     isUpdatedRequired = true;
                  }
               } else {
                  if (nextSL < sl + (sign * 0.01)) {
                     isUpdatedRequired = true;
                  }
               }
               if (isUpdated
               Required) {
                  MqlTradeRequest request = {};
                  MqlTradeResult result = {};
                  ZeroMemory(request);
                  ZeroMemory(result);
                  
                  CHANGE(request, nextSL);
                  logRequest("[WARN] ストップ更新注文を送信します", request);
                  
                  bool isSended = OrderSend(request, result);
                  logResponse("[WARN] 注文送信結果", result);
                  
                  if (!isSended) {
                     checkResult(result);
                  }
               }
            }
         }
         */
}

/*
// OK
bool calcProfit(double &profit) {
   long type = -1;
   double openPrice = -1;
   double currentPrice = -1;
   bool result = false;
   bool isOpenPriceSuccess = GET_OPEN_PRICE(openPrice);
   bool isCurrentPriceSuccess = GET_CURRENT_PRICE(currentPrice);
   bool isTypeSuccess = PositionGetInteger(POSITION_TYPE, type);
   if (isOpenPriceSuccess && isCurrentPriceSuccess && isTypeSuccess) {
      if (type == POSITION_TYPE_BUY) {
         profit = currentPrice - openPrice;
      } else if (type == POSITION_TYPE_SELL) {
         profit = openPrice - currentPrice;
      }
      result = true;
   }
   POST_MESSAGE(_CONFIG.eaName, StringFormat("[calcProfit] profit: %f", profit));
   return result;
}

bool calcNextSL(double base, double current, double &nextSL, int &sign) {
   long type = -1;
   bool isTypeSuccess = PositionGetInteger(POSITION_TYPE, type);
   if (!isTypeSuccess) {
      return false;
   }
   bool isStopUpdatedRequired = false;
   sign = type == POSITION_TYPE_BUY ? 1 : -1;
   while (true) {
      double diff = -1; 
      if (type == POSITION_TYPE_BUY) {      
         diff = current - base;
      } else if (type == POSITION_TYPE_SELL) {
         diff = base - current;
      } else {
         return false;
      }
      //printf("[calcNextSL] current: %f, base: %f, diff: %f", current, base, diff);      
      if (diff > (_CONFIG.sl * 2)) {
         base = base + (sign * _CONFIG.sl);
         isStopUpdatedRequired = true;
      } else {
         break;
      }
   }
   nextSL = base;
   return isStopUpdatedRequired;
}

bool isStopMoved() {
   double open = -1;
   double sl = -1;
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   bool isOpenSuccess = GET_OPEN_PRICE(open);
   bool isSLSuccess = GET_SL_PRICE(sl);
   if (isOpenSuccess && isSLSuccess) {
      if (type == POSITION_TYPE_BUY) {
         return sl > open;
      } else {
         return open > sl;
      }
   }
   return false;
}

*/