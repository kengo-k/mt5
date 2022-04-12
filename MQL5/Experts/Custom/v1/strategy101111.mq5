// in Experts/Custom/v1

/*
 * 051: MAブレイク
 * 111: 固定幅トレール
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

#import "Custom/v1/opener/opener101.ex5"
   string getOpenerName();
   ENUM_ENTRY_COMMAND open(Context &contextMain, Context &contextSub, Config &config);
#import

#import "Custom/v1/closer/closer111.ex5"
   string getCloserName();
   void close(Context &contextMain, Context &contextSub, Config &config);
#import

input double sl = 5;
input double firstProfitTarget = 10;
input double firstProfitValue = 5;
input double trailValue = 10;
input ENUM_TIMEFRAMES subPeriod = 0; // サブ時間足。メインが表示しているチャートの足を使うのでパラメータとして指定はしない
input int shortMaPeriod = 10;
input int longMaPeriod = 100;
input int longlongMaPeriod = 200;

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
   const string EA_NAME = StringFormat("strategy%", magic);
   const double unit = getUnit();
   printf("unit: %f", unit);
   if (unit < 0) {
      POST_MESSAGE(EA_NAME, "[ERROR] cannot get unit");
      ExpertRemove();
      return (INIT_FAILED);
   }

   POST_MESSAGE(EA_NAME, StringFormat("[INFO] start: %s, unit=%f, mainPeriod=%s", Symbol(), unit, getPeriodName(PERIOD_CURRENT)));
   POST_MESSAGE(EA_NAME, StringFormat("[INFO] plugin logic: opener=%s, closer=%s", getOpenerName(), getCloserName()));
   // EAの動作をカスタマイズするためのコンフィグ値の設定
   _config = createConfigure();
   _config.eaName = EA_NAME;
   _config.MAGIC_NUMBER = magic;
   _config.subPeriod = subPeriod;
   _config.sl = sl;
   _config.firstProfitTarget = firstProfitTarget;
   _config.firstProfitValue = firstProfitValue;
   _config.trailValue = trailValue;
   _config.volume = 0.1;
   _config.shortMaPeriod = shortMaPeriod;
   _config.longMaPeriod = longMaPeriod;
   _config.longlongMaPeriod = longlongMaPeriod;
   _config.macdPeriod[0] = 12;
   _config.macdPeriod[1] = 26;
   _config.macdPeriod[2] = 9;
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
