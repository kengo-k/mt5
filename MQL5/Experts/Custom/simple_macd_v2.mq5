// Experts/Custom/simple_macd_v2.mq5
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/common.ex5"
   long createMagicNumber(int prefix, int revision);
#import

#import "Custom/Logics/SimpleMACDLogics_v2.ex5"
  void SimpleMACD_Configure(SimpleMACDConfig &config);
  void SimpleMACD_Init(SimpleMACDContext &contextMain, SimpleMACDContext &contextSub);
  void SimpleMACD_OnTick(SimpleMACDContext &contextMain, SimpleMACDContext &contextSub);
#import

#import "Custom/Logics/createCommand1.ex5"
   ENUM_ENTRY_COMMAND createCommand(SimpleMACDContext &contextMain, SimpleMACDConfig &config);
#import

#import "Custom/Logics/filterCommand0.ex5"
   bool filterCommand(ENUM_ENTRY_COMMAND command, SimpleMACDContext &contextMain, SimpleMACDContext &contextSub, SimpleMACDConfig &config);
#import

#import "Custom/Logics/observe1.ex5"
   void observe(SimpleMACDContext &contextMain, SimpleMACDContext &contextSub, SimpleMACDConfig &config);
#import

#define MAGICNUMBER_PREFIX 100
#define REVISION 1
#define MAGICNUMBER createMagicNumber(MAGICNUMBER_PREFIX, REVISION)

SimpleMACDConfig _config = {};
SimpleMACDContext _contextMain;
SimpleMACDContext _contextSub;

ENUM_ENTRY_COMMAND _createCommand(SimpleMACDContext &context) {
   return createCommand(context, _config);
}

bool _filterCommand(ENUM_ENTRY_COMMAND command, SimpleMACDContext &contextMain, SimpleMACDContext &contextSub) {
   return filterCommand(command, contextMain, contextSub, _config);
}

void _observe(SimpleMACDContext &contextMain, SimpleMACDContext &contextSub) {
   observe(contextMain, contextSub, _config);
}

int OnInit() {

   // このEAの名前
   // ※SLACKのチェンネル名に合わせてあるから変えてはいけない
   const string EA_NAME = "simple_macd_v2!!!";
   PrintFormat("[%s] start", EA_NAME);
   
   // コード値メモ
   /* リターンコード
   10018: TRADE_RETCODE_MARKET_CLOSED 市場が閉鎖中
    */

   // EAの動作をカスタマイズするためのコンフィグ値の設定
   _config.eaName = EA_NAME;
   _config.sl = 0.05;
   _config.tpRatio = 2;
   _config.volume = 0.1;
   _config.mainPeriod = PERIOD_H1; //メイン足
   _config.subPeriod = PERIOD_H1; //サブ足 
   _config.createCommand = _createCommand; //買い売り判断
   _config.filterCommand = _filterCommand; //ポジション構築フィルタ
   _config.observe = _observe; //ティック監視
   _config.MAGIC_NUMBER = MAGICNUMBER;

   SimpleMACD_Configure(_config);
   SimpleMACD_Init(_contextMain, _contextSub);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   
}

void OnTick() {
   SimpleMACD_OnTick(_contextMain, _contextSub);
}
