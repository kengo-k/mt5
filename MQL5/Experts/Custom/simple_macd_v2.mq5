// Experts/Custom/simple_macd_v2.mq5
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SimpleMACDLib.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/SimpleMACDLogics_v2.ex5"
  void SimpleMACD_Configure(string EA_NAME, string TARGET_SYMBOL, double TARGET_STOP, double TARGET_VOLUME);
  void SimpleMACD_Init(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1);
  void SimpleMACD_OnTick(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1);
#import

SimpleMACDContext contextM5;
SimpleMACDContext contextH1;

int OnInit() {
   // このEAの名前
   // ※SLACKのチェンネル名に合わせてあるから変えてはいけない
   const string EA_NAME = "simple_macd_v2!";
   PrintFormat("[%s] start", EA_NAME);
   
   /*
   printf("TRADE_ACTION_DEAL: %d", TRADE_ACTION_DEAL);
   printf("TRADE_ACTION_PENDING: %d", TRADE_ACTION_PENDING);
   printf("TRADE_ACTION_SLTP: %d", TRADE_ACTION_SLTP);
   printf("TRADE_ACTION_MODIFY: %d", TRADE_ACTION_MODIFY);
   printf("TRADE_ACTION_REMOVE: %d", TRADE_ACTION_REMOVE);
   printf("TRADE_ACTION_CLOSE_BY: %d", TRADE_ACTION_CLOSE_BY);
   */
   
   /* リターンコード
   10018: TRADE_RETCODE_MARKET_CLOSED 市場が閉鎖中
    */
   
   SimpleMACD_Configure(EA_NAME, SIMPLE_MACD_TARGET_SYMBOL, 0.05, 0.1);
   SimpleMACD_Init(contextM5, contextH1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   SimpleMACD_OnTick(contextM5, contextH1);
}
