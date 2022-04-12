// in Experts/Custom/v1

/*
 * 051: MAブレイク
 * 001: 固定幅SLTP
 */

#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/SlackLib.mqh>
#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>

#import "Custom/v1/common/common.ex5"
   int notifySlack(string message, string channel);
   long createMagicNumber(string pattern1, string pattern2);
   double getUnit();
   string getPeriodName(ENUM_TIMEFRAMES period);
#import

#import "Custom/v1/main/main1.ex5"
   Config createConfigure();
   void setConfigure(Config &config);
   void init(Context &contextMain, Context &contextSub);
   void handleTick(Context &contextMain, Context &contextSub);
#import

#import "Custom/v1/opener/opener051.ex5"
   string getOpenerName();
   ENUM_ENTRY_COMMAND open(Context &contextMain, Context &contextSub, Config &config);
#import

#import "Custom/v1/closer/closer001.ex5"
   string getCloserName();
   void close(Context &contextMain, Context &contextSub, Config &config);
#import

input double sl = 5; // stop loss (pips)
input double tp = 8; // take profit (pips)
input ENUM_TIMEFRAMES mainPeriod = PERIOD_H1; // main timeframes
input ENUM_TIMEFRAMES subPeriod = PERIOD_H1; // sub timeframes

Config _config;
Context _contextMain;
Context _contextSub;

ENUM_ENTRY_COMMAND _open(Context &contextMain, Context &contextSub) {
   return open(contextMain, contextSub, _config);
}

void _close(Context &contextMain, Context &contextSub) {
   close(contextMain, contextSub, _config);
}

int OnInit() {
   // このEAの名前
   // ※SLACKのチェンネル名に対応させるため変えてはいけない
   const long magic = createMagicNumber(getOpenerName(), getCloserName());
   const string EA_NAME = StringFormat("strategy%d", magic);
   const double unit = getUnit();
   printf("unit: %f", unit);
   if (unit < 0) {
      POST_MESSAGE(EA_NAME, "[ERROR] cannot get unit");
      ExpertRemove();
      return (INIT_FAILED);
   }

   POST_MESSAGE(EA_NAME, StringFormat("[INFO] start: %s, unit=%f, mainPeriod = %s", Symbol(), unit, getPeriodName(PERIOD_CURRENT)));
   POST_MESSAGE(EA_NAME, StringFormat("[INFO] plugin logic: opener=%s, closer=%s", getOpenerName(), getCloserName()));
   // EAの動作をカスタマイズするためのコンフィグ値の設定
   _config = createConfigure();
   _config.eaName = EA_NAME;
   _config.MAGIC_NUMBER = magic;
   _config.subPeriod = subPeriod;
   _config.sl = sl;
   _config.tp = tp;
   _config.tpRatio = 2;
   _config.volume = 0.1;
   _config.open = _open;
   _config.close = _close;

   setConfigure(_config);
   init(_contextMain, _contextSub);

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {
   handleTick(_contextMain, _contextSub);
}
