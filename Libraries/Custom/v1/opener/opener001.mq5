// in Libraries/Custom/v1/opener
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>
#include <Custom/v1/SlackLib.mqh>

#import "Custom/v1/common/common.ex5"
   int notifySlack(string message, string channel);
   bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal);
   bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal);
#import

string getOpenerName() export {
   return "001";
}

/**
 * MACDのシグナルブレイクをエントリタイミングとするロジック
 */
ENUM_ENTRY_COMMAND open(
   Context &contextMain,
   Context &contextSub,
   Config &config
) export {
   CopyBuffer(contextMain.macdHandle, 0, 0, 3, contextMain.macd);
   CopyBuffer(contextMain.macdHandle, 1, 0, 3, contextMain.signal);

   double macd_latest = contextMain.macd[1]; // 確定した最新の(=直近の)MACD値。
   double macd_prev = contextMain.macd[0]; // 確定した最新の一つ前のMACD値。

   double signal_latest = contextMain.signal[1]; // 確定した最新の(=直近の)シグナル値。
   double signal_prev = contextMain.signal[0]; // 確定した最新の一つ前のシグナル値。

   if (checkUpperBreak(macd_latest, macd_prev, signal_latest, signal_prev)) {
      NOTIFY_MESSAGE(config.eaName, "[INFO] 買いサインが発生しました");
      return ENTRY_COMMAND_BUY;
   }

   if (checkLowerBreak(macd_latest, macd_prev, signal_latest, signal_prev)) {
      NOTIFY_MESSAGE(config.eaName, "[INFO] 売りサインが発生しました");
      return ENTRY_COMMAND_SELL;
   }

   return ENTRY_COMMAND_NOOP;
}
