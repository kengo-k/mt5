// Experts/Custom/simple_macd_v2.mq5
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/SimpleMACDLogics_v2.ex5"
  void SimpleMACD_Configure(SimpleMACDConfig &config);
  void SimpleMACD_Init(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1);
  void SimpleMACD_OnTick(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1);
#import

SimpleMACDContext contextM5;
SimpleMACDContext contextH1;

int OnInit() {

   // このEAの名前
   // ※SLACKのチェンネル名に合わせてあるから変えてはいけない
   const string EA_NAME = "simple_macd_v2";
   PrintFormat("[%s] start", EA_NAME);

   // コード値メモ
   /* リターンコード
   10018: TRADE_RETCODE_MARKET_CLOSED 市場が閉鎖中
    */

   // EAの動作をカスタマイズするためのコンフィグ値の設定
   SimpleMACDConfig config = {};
   config.eaName = EA_NAME;
   config.symbol = Symbol();
   config.sl = 0.05;
   config.volume = 0.1;

   SimpleMACD_Configure(config);
   SimpleMACD_Init(contextM5, contextH1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
   SimpleMACD_OnTick(contextM5, contextH1);
}
