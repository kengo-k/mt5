// in Experts/Custom/v1
//
// pattern: 2 - MACDがシグナルをブレイクしている状態でエントリ(ブレイクしたタイミングでエントリではない)
// revision: a - MACDの値が敷居値を超えていることを条件とするフィルタを使用

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/SlackLib.mqh>
#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>

const int PATTERN = 2;
const char REVISION = 'a';

#import "Custom/v1/common/common.ex5"
   int notifySlack(string message, string channel);
   long createMagicNumber(int pattern, char revision);
   double getUnit();
#import

#import "Custom/v1/main/main1.ex5"
  void configure(Config &config);
  void init(Context &contextMain, Context &contextSub);
  void handleTick(Context &contextMain, Context &contextSub);
#import

#import "Custom/v1/command/createCommand2.ex5"
   string getCommandName();
   ENUM_ENTRY_COMMAND createCommand(Context &contextMain, Config &config);
#import

#import "Custom/v1/filter/filterCommand3.ex5"
   string getFilterName();
   bool filterCommand(ENUM_ENTRY_COMMAND command, Context &contextMain, Context &contextSub, Config &config);
#import

#import "Custom/v1/observer/observe1.ex5"
   string getObserverName();
   void observe(Context &contextMain, Context &contextSub, Config &config);
#import

#define MAGICNUMBER createMagicNumber(PATTERN, REVISION)

input double sl = 5; // stop loss (pips)
input double tp = 8; // take profit (pips)
input double macdThreshold = 0.0009; // macd threshold
input ENUM_TIMEFRAMES mainPeriod = PERIOD_H1; // main timeframes
input ENUM_TIMEFRAMES subPeriod = PERIOD_H1; // sub timeframes

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
   // ※SLACKのチェンネル名に対応させるため変えてはいけない
   const string EA_NAME = StringFormat("strategy_%02d%C", PATTERN, REVISION);
   const double unit = getUnit();
   if (unit < 0) {
      POST_MESSAGE(EA_NAME, "[ERROR] cannot get unit");
      ExpertRemove();
      return (INIT_FAILED);
   }
   POST_MESSAGE(EA_NAME, StringFormat("[INFO] %s(%d) start - %s, unit: %f", EA_NAME, MAGICNUMBER, Symbol(), unit));
   POST_MESSAGE(EA_NAME, StringFormat("[INFO] plugin logic - command: %s, filter: %s, observe: %s", getCommandName(), getFilterName(), getObserverName()));
   // EAの動作をカスタマイズするためのコンフィグ値の設定
   _config.eaName = EA_NAME;
   _config.sl = sl;
   _config.tp = tp;
   _config.tpRatio = 2;
   _config.volume = 0.1;
   _config.mainPeriod = mainPeriod; //メイン足
   _config.subPeriod = subPeriod; //サブ足
   _config.macdThreshold = macdThreshold;
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
