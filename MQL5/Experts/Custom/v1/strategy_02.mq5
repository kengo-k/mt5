// in Experts/Custom/v1
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>

#import "Custom/v1/common/common.ex5"
   long createMagicNumber(int prefix, int revision);
   double getUnit();
#import

#import "Custom/v1/main/main1.ex5"
  void configure(Config &config);
  void init(Context &contextMain, Context &contextSub);
  void handleTick(Context &contextMain, Context &contextSub);
#import

#import "Custom/v1/command/createCommand1.ex5"
   ENUM_ENTRY_COMMAND createCommand(Context &contextMain, Config &config);
#import

#import "Custom/v1/filter/filterCommand0.ex5"
   bool filterCommand(ENUM_ENTRY_COMMAND command, Context &contextMain, Context &contextSub, Config &config);
#import

#import "Custom/v1/observer/observe2.ex5"
   void observe(Context &contextMain, Context &contextSub, Config &config);
#import

#define MAGICNUMBER_PREFIX 100
#define REVISION 1
#define MAGICNUMBER createMagicNumber(MAGICNUMBER_PREFIX, REVISION)

Config _config = {};
Context _contextMain;
Context _contextSub;

ENUM_ENTRY_COMMAND _createCommand(Context &context) {
   return createCommand(context, _config);
}

bool _filterCommand(ENUM_ENTRY_COMMAND command, Context &contextMain, Context &contextSub) {
   return filterCommand(command, contextMain, contextSub, _config);
}

void _observe(Context &contextMain, Context &contextSub) {
   observe(contextMain, contextSub, _config);
}

int OnInit() {

   // このEAの名前
   // ※SLACKのチェンネル名に合わせてあるから変えてはいけない
   const string EA_NAME = "simple_macd_v2!!";
   PrintFormat("[%s] start", EA_NAME);
   
   // コード値メモ
   /* リターンコード
   10018: TRADE_RETCODE_MARKET_CLOSED 市場が閉鎖中
    */

   // EAの動作をカスタマイズするためのコンフィグ値の設定
   _config.eaName = EA_NAME;
   _config.sl = 5;
   _config.tp = 10;
   _config.unit = getUnit();
   _config.tpRatio = 2;
   _config.volume = 0.1;
   _config.mainPeriod = PERIOD_H1; //メイン足
   _config.subPeriod = PERIOD_H1; //サブ足 
   _config.createCommand = _createCommand; //買い売り判断
   _config.filterCommand = _filterCommand; //ポジション構築フィルタ
   _config.observe = _observe; //ティック監視
   _config.MAGIC_NUMBER = MAGICNUMBER;

   configure(_config);
   init(_contextMain, _contextSub);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   
}

void OnTick() {
   handleTick(_contextMain, _contextSub);
}
