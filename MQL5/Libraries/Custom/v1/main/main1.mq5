// Libraries/Custom/Logics/SimpleMACDLogics_v2.mq5

/**
 [仕様]
 ・メインとサブ２つの足を使用する
 ・サブ足は長期の方向性を特定するための足でメイン足よりも大きな時間足を指定する
 ・長期の方向性に合致している時のみポジションを建てる
 ・メイン足が条件に合致したときにエントリする
 ・その他ストップの設定、利益確定などの各種コアロジックは外部から指定可能とする(関数ポインタ)
*/

#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/v1/SlackLib.mqh>
#include <Custom/v1/Config.mqh>
#include <Custom/v1/Context.mqh>

#import "Custom/v1/common/common.ex5"
   int notifySlack(string message, string channel);
   bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal);
   bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal);
   void logRequest(string eaName, string header, MqlTradeRequest &request);
   void logResponse(string eaName, string header, MqlTradeResult &result);
   void buy(MqlTradeRequest &request, double sl, double volume, long magic);
   void sell(MqlTradeRequest &request, double sl, double volume, long magic);
   void checkTradeResult(MqlTradeResult &result);
   double calcPositionPipsBetweenCurrentAndStop(double unit);
   double getPositionCurrentPrice();
   double getPositionSL();
#import

Config _CONFIG;

// 予兆の通知済みフラグ
bool isOmenNotified;

/**
 * パラメータ等の情報を設定する処理!
 */
void configure(
   Config &CONFIG
) export {
   _CONFIG = CONFIG;
   NOTIFY_MESSAGE(_CONFIG.eaName, StringFormat("start %s using %d/%d period", _CONFIG.eaName, _CONFIG.mainPeriod, _CONFIG.subPeriod));
}

/**
 * EAの初期処理
 *
 * インディケーターや各種変数の初期化等の処理を行う。
 */
void init(Context &contextMain, Context &contextSub) export {
   contextMain.macdHandle = iMACD(Symbol(), _CONFIG.mainPeriod, 12, 26, 9, PRICE_CLOSE);
   contextMain.barCount = -1;
   contextSub.macdHandle = iMACD(Symbol(), _CONFIG.subPeriod, 12, 26, 9, PRICE_CLOSE);
   isOmenNotified = false;
}

/**
 * Tickが生成されるたびに呼び出される処理
 */
void handleTick(Context &contextMain, Context &contextSub) export {
      
   // ローソク足が新しく生成されているか数を確認
   int newM5BarCount = Bars(Symbol(), _CONFIG.mainPeriod);
   if (contextMain.barCount == -1) {
      contextMain.barCount = newM5BarCount;
   }

   // 予兆の通知
   // ポジションを持っている場合は(新規にポジションを建てないので)通知する必要はないが
   // 一応注意を促しておいたほうがいいため通知だけはする。
   // 無制限に出すと通知であふれるため同じ足の中で一度だけ出す
   if (!isOmenNotified) {
      isOmenNotified = notifyOmen(contextMain, contextSub);
   }

   // ポジションを保持している場合ティックの動きを監視して、利益がでている場合はストップを移動させて利益を確定させる
   if (hasPosition()) {
      _CONFIG.observe(contextMain, contextSub);
   }

   // 新しい足が生まれた場合
   if (newM5BarCount > contextMain.barCount) {
      contextMain.barCount = newM5BarCount;
      onNewBarCreated(contextMain, contextSub);
      // 通知済みフラグをリセット
      isOmenNotified = false;
   }
}

/**
 * 新しい足が生成された時の処理
 *
 * 新規ポジションの構築/決済などの処理を行う
 */
void onNewBarCreated(Context &contextMain, Context &contextSub) {

   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   ZeroMemory(request);
   ZeroMemory(result);
   
   logNewBar(contextMain, contextSub);
   if (hasPosition()) {
     // logNewBar(contextMain, contextSub);
   } else {
      // 新規ポジションを建てるかどうかの判定を行う
      ENUM_ENTRY_COMMAND command = _CONFIG.createCommand(contextMain);
      // フィルタを適用して実際にポジションを建てるかどうかチェックを行う
      bool accept = _CONFIG.filterCommand(command, contextMain, contextSub);
      
      if (command == ENTRY_COMMAND_BUY && accept) {
         buy(request, (_CONFIG.sl * _CONFIG.unit), _CONFIG.volume, _CONFIG.MAGIC_NUMBER);
         logRequest(_CONFIG.eaName, "[WARN] 新規買い注文を送信します", request);
         
         bool isSended = OrderSend(request, result);
         logResponse(_CONFIG.eaName, "[WARN] 注文送信結果", result);

         if (!isSended) {
            checkTradeResult(result);
         }
      }

      if (command == ENTRY_COMMAND_SELL && accept) {
         sell(request, (_CONFIG.sl * _CONFIG.unit), _CONFIG.volume, _CONFIG.MAGIC_NUMBER);
         logRequest(_CONFIG.eaName, "[WARN] 新規売り注文を送信します", request);
         
         bool isSended = OrderSend(request, result);
         logResponse(_CONFIG.eaName, "[WARN] 注文送信結果", result);

         if (!isSended) {
            checkTradeResult(result);
         }         
      }
   }
}

// OK
/**
 * MACDがシグナル値に到達した瞬間に通知する。
 * サインを出すのは足が確定した後となるが、あらかじめ臨戦態勢に入っていないと遅れてしまうので
 * サイン発生前の予兆として使う。
 */
bool notifyOmen(Context &contextMain, Context &contextSub) {
   
   CopyBuffer(contextMain.macdHandle, 0, 0, 2, contextMain.macd);
   CopyBuffer(contextMain.macdHandle, 1, 0, 2, contextMain.signal);

   double macd_current = contextMain.macd[1]; // tickのMACD値。
   double macd_latest = contextMain.macd[0]; // 確定した最新のMACD値。

   double signal_current = contextMain.signal[1]; // tickのシグナル値。
   double signal_latest = contextMain.signal[0]; // 確定したのシグナル値。

   bool ret = false;

   // MACDがシグナルを上方にブレイク
   if (checkUpperBreak(macd_current, macd_latest, signal_current, signal_latest)) {
      NOTIFY_MESSAGE(
         _CONFIG.eaName
         , StringFormat(
            "[INFO] MACDのシグナル上方ブレイク予兆が発生しました - macd: %f => %f"
            , macd_current
            , macd_latest
           )
      );
      ret = true;
   }

   // MACDがシグナルを下方にブレイク
   if (checkLowerBreak(macd_current, macd_latest, signal_current, signal_latest)) {
      NOTIFY_MESSAGE(
         _CONFIG.eaName
         , StringFormat(
            "[INFO] MACDのシグナル下方ブレイク予兆が発生しました - macd: %f => %f"
            , macd_current
            , macd_latest
            ));
      ret = true;
   }

   return ret;
}

// OK
/**
 * ポジションが存在しているかどうかを確認する
 */
bool hasPosition() {
   int posCount = 0;
   for (int i = 0; i < PositionsTotal(); i++) {
      string symbol = PositionGetSymbol(i);
      if (StringLen(symbol) > 0) {
         long magic = PositionGetInteger(POSITION_MAGIC);
         if (magic == _CONFIG.MAGIC_NUMBER) {
            posCount++;
         }
      }
   }
   if (posCount == 0) {
      return false;
   } else if (posCount == 1) {
      return true;
   } else {
      // ポジションは同時に複数持たない方針であるため
      // ポジション数が1でも0でもない場合は何らかの不具合であるため即座に処理を終了させる
      printf("ポジション数が不正です");
      ExpertRemove();
      return false;
   }
}

void logNewBar(Context &contextMain, Context &contextSub) {
   
   CopyBuffer(contextMain.macdHandle, 0, 0, 3, contextMain.macd);
   CopyBuffer(contextMain.macdHandle, 1, 0, 3, contextMain.signal);

   double macd_latest = contextMain.macd[1]; // 確定した最新の(=直近の)MACD値。
   double macd_prev = contextMain.macd[0]; // 確定した最新の一つ前のMACD値。

   double signal_latest = contextMain.signal[1]; // 確定した最新の(=直近の)シグナル値。
   double signal_prev = contextMain.signal[0]; // 確定した最新の一つ前のシグナル値。

   int digits = Digits();

   // 元から正規化されてるから多分Normalizeしなくてもよさそう
   // 取得した値になんらかの加工した場合にすればよさそう
   double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), digits);
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), digits);
   double spread = MathAbs(NormalizeDouble(ask - bid, digits));
   
   if (hasPosition()) {
      double current = getPositionCurrentPrice();
      double sl = getPositionSL();
      double pips = calcPositionPipsBetweenCurrentAndStop(_CONFIG.unit);
      POST_MESSAGE(
         _CONFIG.eaName
         , StringFormat(
            "[INFO][HAS_POSITION] new bar was created, bid: %s, ask: %s, spread: %f, current: %f, sl: %f, expect profit(pips): %f"
            , DoubleToString(bid, digits)
            , DoubleToString(ask, digits)
            , spread
            , current
            , sl
            , pips
           )
      );   
   } else {
      POST_MESSAGE(
         _CONFIG.eaName
         , StringFormat(
            "[INFO] new bar was created, macd: %f, signal: %f, bid: %s, ask: %s, spread: %f"
            , macd_latest
            , signal_latest
            , DoubleToString(bid, digits)
            , DoubleToString(ask, digits)
            , spread
           )
      );
   }

}