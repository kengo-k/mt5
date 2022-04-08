// in Libraries/Custom/v1/command
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

string getCommandName() export {
   return "command2";
}

/**
 * MACDがシグナルを超えていることをエントリタイミングとするロジック
 */
ENUM_ENTRY_COMMAND createCommand(
   Context &contextMain,
   Config &config
) export {
   CopyBuffer(contextMain.macdHandle, 0, 0, 2, contextMain.macd);
   CopyBuffer(contextMain.macdHandle, 1, 0, 2, contextMain.signal);

   double macd_latest = contextMain.macd[0]; // 確定した最新の(=直近の)MACD値。
   double signal_latest = contextMain.signal[0]; // 確定した最新の(=直近の)シグナル値。

   if (macd_latest > 0 && macd_latest > signal_latest) {
      NOTIFY_MESSAGE(config.eaName, "[INFO] 買いサインが発生しました");
      return ENTRY_COMMAND_BUY;
   }

   if (macd_latest < 0 && macd_latest < signal_latest) {
      NOTIFY_MESSAGE(config.eaName, "[INFO] 売りサインが発生しました");
      return ENTRY_COMMAND_SELL;
   }

   return ENTRY_COMMAND_NOOP;
}
