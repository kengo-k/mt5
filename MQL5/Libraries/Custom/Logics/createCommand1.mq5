// Libraries/Custom/Logics/createCommand1.mq5
#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import
#include <Custom/SlackLib.mqh>

#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Logics/common.ex5"
   bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal);
   bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal);
#import

/**
 * MACDのシグナルブレイクをエントリタイミングとするロジック
 */
ENUM_ENTRY_COMMAND createCommand(
   Context &contextMain,
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
