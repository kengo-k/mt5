// Experts/Custom/simple_macd_v2.mq5
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SimpleMACDLib.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/SimpleMACDLogics_v2.ex5"
  void SimpleMACD_Configure(string EA_NAME, string TARGET_SYMBOL, double TARGET_STOP, double TARGET_LIMIT, double TARGET_TRAIL);
  void SimpleMACD_Init(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1);
  void SimpleMACD_OnTick(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1);
#import

SimpleMACDContext contextM5;
SimpleMACDContext contextH1;

int OnInit() {
   SimpleMACD_Configure("simple_macd_v2", SIMPLE_MACD_TARGET_SYMBOL, 0.05, 0.1, 0.025);
   SimpleMACD_Init(contextM5, contextH1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   SimpleMACD_OnTick(contextM5, contextH1);
}
