// Libraries/Custom/Logics/SimpleMACDLogics_v2.mq5
/**
　・M5をメインに使用しトレンド方向に合わせるためにサブとしてH1も使用する
　・M5で条件を満たしかつH1と同じ方向の場合にエントリサインを出す
 ・条件は確定した直近のMACDがシグナルをブレイクすることとする
 ・基本は5分以内に決済する。ただし損失がでている場合はストップに狩られるまで決済を延長する。
 ・利益確定の指値は基本入れない(5分で決着するはずだから大丈夫のはず。離席、就寝する場合はもちろん入れる)する
 ・利益目標達成の場合はストップを移動し利益を確定しストップが狩られるまで延長する
 ・利益はでているが目標未達の場合はプラスのまま決済し撤退する
*/

#property library
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Custom/SlackLib.mqh>
#include <Custom/SimpleMACDConfig.mqh>
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import

#define MAGICNUMBER 123456
#define BUY(request, sl, volume) createNewOrder(request, ORDER_TYPE_BUY, SYMBOL_ASK, SYMBOL_BID, -sl, volume);
#define SELL(request, sl, volume) createNewOrder(request, ORDER_TYPE_SELL, SYMBOL_BID, SYMBOL_ASK, +sl, volume);
#define CLOSE(request) createCloseOrder(request)
#define CHANGE(request, newSL) createChangeOrder(request, newSL)
#define GET_POSITION_TYPE (type) PositionGetInteger(POSITION_TYPE, type);
#define GET_OPEN_PRICE(price) PositionGetDouble(POSITION_PRICE_OPEN, price);
#define GET_CURRENT_PRICE(price) PositionGetDouble(POSITION_PRICE_CURRENT, price);
#define GET_SL_PRICE(sl) PositionGetDouble(POSITION_SL, sl);
#define GET_TP_PRICE(tp) PositionGetDouble(POSITION_TP, tp);

SimpleMACDConfig _CONFIG;

// 予兆の通知済みフラグ
bool isOmenNotified;

// 建玉を保持しているかどうか
//bool hasPosition;
// 利益が確定されているかどうか
//bool isProfitFixed;

/**
 * パラメータ等の情報を設定する処理
 */
void SimpleMACD_Configure(
   SimpleMACDConfig &CONFIG
) export {
   _CONFIG = CONFIG;
   NOTIFY_MESSAGE(_CONFIG.eaName, StringFormat("start %s", _CONFIG.eaName));
}

/**
 * EAの初期処理
 *
 * インディケーターや各種変数の初期化等の処理を行う。
 */
void SimpleMACD_Init(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) export {
   contextM5.macdHandle = iMACD(_CONFIG.symbol, PERIOD_M5, 12, 26, 9, PRICE_CLOSE);
   contextM5.barCount = -1;
   contextH1.macdHandle = iMACD(_CONFIG.symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);

   //hasPosition = false;
   //isProfitFixed = false;
   isOmenNotified = false;

   // 基本方針: ポジションを複数持つことはしない=ポジションをすでにもっているときは
   // 追加の注文は行わないようにするため初期起動時にポジションが存在することを確認する。
   // → PositionsTotal()で未決済ポジションの数を返せる。これが0より大きければポジション保持済み
   //
   // ただしプログラムが建てたポジションと手動で建てたポジションを混同したくないので別途対策が必要かもしれない
   // ※EA毎に固有のMagicNumberを設定することで区別できる模様。
   // (MT5で手動することは多分ないとは思うが)
   //
   // 保持済みのポジションに関する各種情報を取得するには、上記関数で取得したポジション数でループして
   // PostionGetInteger()やPositionGetString()などに対応するプロパティのENUMを指定して取得する。
   // ※当面は手動でポジションを建てないので上記の対策は実装しない
}

/**
 * Tickが生成されるたびに呼び出される処理
 */
void SimpleMACD_OnTick(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) export {
   
   //double ask = SymbolInfoDouble(_TARGET_SYMBOL, SYMBOL_ASK);
   //double bid = SymbolInfoDouble(_TARGET_SYMBOL, SYMBOL_BID);
   //int digits = Digits();
   //printf("[ontick] ask: %s, bid: %s", DoubleToString(ask, digits), DoubleToString(bid, digits));
   
   // ローソク足が新しく生成されているか数を確認
   int newM5BarCount = Bars(_CONFIG.symbol, PERIOD_M5);
   if (contextM5.barCount == -1) {
      contextM5.barCount = newM5BarCount;
   }

   // 予兆の通知
   // ポジションを持っている場合は(新規にポジションを建てないので)通知する必要はないが
   // 一応注意を促しておいたほうがいいため通知だけはする。
   // 無制限に出すと通知であふれるため同じ足の中で一度だけ出す
   if (!isOmenNotified) {
      isOmenNotified = notifyOmen(contextM5, contextH1);
   }

   // ポジションを保持している場合ティックの動きを監視して、利益がでている場合はストップを移動させて利益を確定させる
   bool hasPosition = isPositionExist();
   if (hasPosition) {
      bool isSelectSuccess = selectPosition();
      if (isSelectSuccess) {
         double current = -1;
         double open = -1;
         double sl = -1;
         bool isCurrentSuccess = GET_CURRENT_PRICE(current);
         bool isOpenSuccess = GET_OPEN_PRICE(open);
         bool isSLSuccess = GET_SL_PRICE(sl);
         if (isCurrentSuccess && isOpenSuccess && isSLSuccess) {
            double nextSL = -1;
            int sign = 0;
            bool isNextSLSuccess = calcNextSL(open, current, nextSL, sign);
            if (isNextSLSuccess) {
               bool isUpdatedRequired = false;
               if (sign == 1) {
                  if (nextSL > sl + (sign * 0.01)) {
                     isUpdatedRequired = true;
                  }               
               } else {
                  if (nextSL < sl + (sign * 0.01)) {
                     isUpdatedRequired = true;
                  }
               }
               if (isUpdatedRequired) {
                  MqlTradeRequest request = {};
                  MqlTradeResult result = {};
                  ZeroMemory(request);
                  ZeroMemory(result);
                  
                  CHANGE(request, nextSL);
                  logRequest("[WARN] ストップ更新注文を送信します", request);
                  
                  bool isSended = OrderSend(request, result);
                  logResponse("[WARN] 注文送信結果", result);
                  
                  if (!isSended) {
                     checkResult(result);
                  }
               }
            }
         }
      }
   }

   // 新しい足が生まれた場合
   if (newM5BarCount > contextM5.barCount) {
      contextM5.barCount = newM5BarCount;
      onNewBarCreated(contextM5, contextH1);
      // 通知済みフラグをリセット
      isOmenNotified = false;
   }
}

/**
 * 新しい足が生成された時の処理
 *
 * 新規ポジションの構築/決済などの処理を行う
 */
void onNewBarCreated(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) {

   // 建玉を保持しているかをチェック
   // 保持している場合、決済条件を満たしている場合は決済してこの足における処理は処理する
   //
   // 決済条件:
   //    利益確定のストップが入っていない＆利益が出ている(=利益は出ているけど利益目標には到達してない)場合
   // 根拠:
   //    損切はストップに狩られるまで何もしない。回復する可能性があるので少しでも引き延ばす。
   //    ストップはここまでの損失なら受け入れてもよいという額なので待機するという考え方をする。
   // 　　　　　
   //    ストップを移動して利益が確定した状況になっている場合は安心して利益をさらに伸ばしたいため決済せずに放置する
   //    最低目標利益に到達しないまま新しい足が発生した場合はエントリのタイミングとして適切ではなかったと判断し
   //    利益がでているならその時点で確定して逃げる。
   //    ※もちろん放置してれば普通に勝つ可能性もあるが

   // 指標値を最新から3個分取る
   // [0]: 直近のさらにひとつ前のローソク足
   // [1]: 直近 ※最新の確定したローソク足(基本この値を見る)
   // [2]: 現在値 ※ローソク足が確定してないためまだ変動する ※未使用
   CopyBuffer(contextM5.macdHandle, 0, 0, 3, contextM5.macd);
   CopyBuffer(contextM5.macdHandle, 1, 0, 3, contextM5.signal);

   double macd_latest = contextM5.macd[1]; // 確定した最新の(=直近の)MACD値。
   double macd_prev = contextM5.macd[0]; // 確定した最新の一つ前のMACD値。

   double signal_latest = contextM5.signal[1]; // 確定した最新の(=直近の)シグナル値。
   double signal_prev = contextM5.signal[0]; // 確定した最新の一つ前のシグナル値。

   double h1dir = checkTrend(contextH1);
   int digits = Digits();

   // 元から正規化されてるから多分Normalizeしなくてもよさそう
   // 取得した値になんらかの加工した場合にすればよさそう
   double ask = NormalizeDouble(SymbolInfoDouble(_CONFIG.symbol, SYMBOL_ASK), digits);
   double bid = NormalizeDouble(SymbolInfoDouble(_CONFIG.symbol, SYMBOL_BID), digits);
   double spread = MathAbs(NormalizeDouble(ask - bid, digits));

   // 新しい足が生成されたログを表示
   POST_MESSAGE(
      _CONFIG.eaName
      , StringFormat(
         "[INFO] new bar was created, macd: %f, signal: %f, h1dir: %f, bid: %s, ask: %s, spread: %f"
         , macd_latest
         , signal_latest
         , h1dir
         , DoubleToString(bid, digits)
         , DoubleToString(ask, digits)
         , spread
        )
   );

   // ポジションの有無によってこの後の処理を分岐させる。
   // ポジションがない場合は条件を満たすかどうか判定し満たしていた場合新規の注文を出す。
   // ポジションが無いと判定したにもかかわらず実はポジションが存在することは起こりえない
   // (ポジションを建てるのはこの後の処理なので)
   //
   // すでにポジションがある場合は
   // ・そのままポジションを持ち続ける
   // ・その場でポジションを決済する
   // のどちらかを行う。
   //
   // ポジションを持ち続ける条件は
   // ・損失がある(がストップ狩りはされてない)
   // ・ストップが移動されている場合(=利益確定されているのでより利益を伸ばすため)
   //
   // ポジションを決済する条件は
   // ・ストップが移動されていないが利益が出ている場合(=目標利益に到達できていないためエントリタイミングの誤りと判断してプラスのまま撤退するため)
   // この場合はポジションがあると判断していたにも関わらずポジションがすでに存在していないことが起こりえる(かもしれない)
   // (その場合は決済の注文を出した際のretCodeが何らかのエラーを返すはず)

   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   ZeroMemory(request);
   ZeroMemory(result);

   bool hasPosition = isPositionExist();
   if (hasPosition) {
      // ストップが移動されたかどうかを判定する
      // 買いの場合、ストップ価格 > 約定価格(売りは逆)であればストップが移動されたと判断できる
      double open = -1;
      double sl = -1;
      double profit = -1;
      bool isOpenSuccess = GET_OPEN_PRICE(open);
      bool isSLSuccess = GET_SL_PRICE(sl);
      bool isProfitSuccess = calcProfit(profit);
      if (isOpenSuccess && isSLSuccess && isProfitSuccess) {
         bool stopMoved = isStopMoved();
         bool isPositionKeeped = profit < 0 || stopMoved;
         // ポジションキープではない場合は決済する
         if (!isPositionKeeped) {
            // 決済する場合はOrderSendに既存のチケット番号を指定することで反対売買となる
            // (両建て可能口座の場合のみ。両建てNG口座の場合はチケット指定は不要)
            CLOSE(request);
            logRequest("[WARN] 利益確定注文を送信します", request);
            
            bool isSended = OrderSend(request, result);
            logResponse("[WARN] 注文送信結果", result);   
            
            if (!isSended) {
               checkResult(result);
            }
         }
      }
   } else {

      // 新規注文

      // MACDがシグナルを上方にブレイク
      if (checkUpperBreak(macd_latest, macd_prev, signal_latest, signal_prev) && h1dir > 0) {
         NOTIFY_MESSAGE(
            _CONFIG.eaName
            , "[INFO] MACDがシグナルを上方ブレイクしました"
         );

         // 注文送信
         BUY(request, _CONFIG.sl, _CONFIG.volume);
         logRequest("[WARN] 新規買い注文を送信します", request);
         
         bool isSended = OrderSend(request, result);
         logResponse("[WARN] 注文送信結果", result);

         // 注文の送信に失敗した場合なんらかのバグの可能性があるのでEAを停止させる
         // ※送信に成功しただけであってポジションが正常に生成されたことを保証するわけではないので注意
         // TODO エラーハンドリング周り
         // TODO エラーコードのロギング
         if (!isSended) {
            checkResult(result);
         }

         // 正常に処理が続行しているかを判定する必要があるかどの項目をどう判定すべきかわかってないのでとりあえずログだけ出しとく

      }

      // MACDがシグナルを下方にブレイク
      if (checkLowerBreak(macd_latest, macd_prev, signal_latest, signal_prev) && h1dir < 0) {
         NOTIFY_MESSAGE(
            _CONFIG.eaName
            , "[INFO] MACDがシグナルを下方ブレイクしました"
         );
         
         // 注文送信
         SELL(request, _CONFIG.sl, _CONFIG.volume);
         logRequest("[WARN] 新規売り注文を送信します", request);
         
         bool isSended = OrderSend(request, result);
         logResponse("[WARN] 注文送信結果", result);

         // 注文の送信に失敗した場合なんらかのバグの可能性があるのでEAを停止させる
         // ※送信に成功しただけであってポジションが正常に生成されたことを保証するわけではないので注意
         // TODO エラーハンドリング周り
         // TODO エラーコードのロギング
         if (!isSended) {
            checkResult(result);
         }

         // 正常に処理が続行しているかを判定する必要があるかどの項目をどう判定すべきかわかってないのでとりあえずログだけ出しとく
         NOTIFY_MESSAGE(
            _CONFIG.eaName,
            StringFormat(
               "order sended - request_id: %d, retcode: %d, retcode_external: %d, deal: %d, order: %d, "
               , result.request_id
               , result.retcode
               , result.retcode_external
               , result.deal
               , result.order
            )
         );         
      }
   }
}

/**
 * ストップが移動されたかどうかを判定する。
 * ストップが移動された=利益が確定していると判断する
 *
 * 買いの場合: 
 */
bool isStopMoved() {
   double open = -1;
   double sl = -1;
   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   bool isOpenSuccess = GET_OPEN_PRICE(open);
   bool isSLSuccess = GET_SL_PRICE(sl);
   if (isOpenSuccess && isSLSuccess) {
      if (type == POSITION_TYPE_BUY) {
         return sl > open;
      } else {
         return open > sl;
      }
   }
   return false;
}

/**
 * 注文のリクエスト情報をログに出力
 */
void logRequest(string header, MqlTradeRequest &request) {
   NOTIFY_MESSAGE(
      _CONFIG.eaName,
      StringFormat(
         "%s - %s, price: %f, volume: %f, stop: %f, fillMode: %d"
         , header
         , request.symbol
         , request.price
         , request.volume
         , request.sl
         , request.type_filling
      )
   );
}

/**
 * 注文のレスポンス情報をログに出力
 */
void logResponse(string header, MqlTradeResult &result) {
   // retCode
   // 10009: TRADE_RETCODE_DONE - リクエスト完了
   NOTIFY_MESSAGE(
      _CONFIG.eaName,
      StringFormat(
         "%s - request_id: %d, retcode: %d, retcode_external: %d, deal: %d, order: %d, "
         , header
         , result.request_id
         , result.retcode
         , result.retcode_external
         , result.deal
         , result.order
      )
   );
}

/**
 * 注文送信結果を判定して必要な場合システムを停止する等の処理を行う
 */
void checkResult(MqlTradeResult &result) {
   bool isAbortRequired = true;
   if (result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
      isAbortRequired = false;
   }
   if (isAbortRequired) {
      ExpertRemove();
   }
}

// OK
/**
 * 新規注文のリクエストを生成する
 */
void createNewOrder(
   MqlTradeRequest &request
   , ENUM_ORDER_TYPE type // BUY/SELL
   , ENUM_SYMBOL_INFO_DOUBLE targetSymbolInfo // 注文のASK/BID
   , ENUM_SYMBOL_INFO_DOUBLE oppositeSymbolInfo // 反対側のASK/BID ※ストップの算出に使う
   , double sl
   , double volume
) {
   double targetPrice = SymbolInfoDouble(_CONFIG.symbol, targetSymbolInfo);
   double oppositePrice = SymbolInfoDouble(_CONFIG.symbol, oppositeSymbolInfo);
   request.action = TRADE_ACTION_DEAL;
   request.type = type;
   request.symbol = _CONFIG.symbol;
   request.volume = _CONFIG.volume;
   request.price = targetPrice;
   
   // 指定したボリュームを調達できない場合にどのように振る舞うかのモード
   // キャンセルする/可能な量のみでポジションを立てる/etc
   request.type_filling = ORDER_FILLING_IOC;
   
   // ストップを設定する
   // ※利益確定の指値はとりあえず入れない方針でやってみる
   // (ストップを動かしてトレーリングする)
   request.sl = oppositePrice + sl;

   request.deviation = 3; // 許容スリッページ
   request.expiration = ORDER_TIME_DAY; // 有効期限
   request.comment = ""; // 任意のコメント
   request.magic = MAGICNUMBER;
}

/**
 * 決済注文のリクエストを生成する
 */
void createCloseOrder(
   MqlTradeRequest &request
) {
   ulong ticketNo = PositionGetInteger(POSITION_TICKET);
   ENUM_POSITION_TYPE entryType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   ENUM_ORDER_TYPE closeType = ORDER_TYPE_BUY;
   ENUM_SYMBOL_INFO_DOUBLE symbolInfo = SYMBOL_BID;
   request.action = TRADE_ACTION_DEAL;
   request.position = ticketNo;
   if (entryType == POSITION_TYPE_BUY) {
      symbolInfo = SYMBOL_ASK;
      closeType = ORDER_TYPE_SELL;
   }
   request.volume = _CONFIG.volume;
   request.deviation = 3;
   request.magic = MAGICNUMBER;
   request.price = SymbolInfoDouble(_CONFIG.symbol, symbolInfo);
   request.type = closeType;   
   request.type_filling = ORDER_FILLING_IOC;
}

/**
 * ストップを変更するリクエストを生成する
 */
void createChangeOrder(
   MqlTradeRequest &request
   , double newSL
) {
   ulong ticketNo = PositionGetInteger(POSITION_TICKET);
   string symbol = PositionGetString(POSITION_SYMBOL);
   double tp = PositionGetDouble(POSITION_TP);
   ENUM_POSITION_TYPE entryType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   ENUM_ORDER_TYPE closeType = ORDER_TYPE_BUY;
   ENUM_SYMBOL_INFO_DOUBLE symbolInfo = SYMBOL_BID;
   request.action = TRADE_ACTION_SLTP;
   request.position = ticketNo;
   request.symbol = symbol;
   request.sl = newSL;
   request.tp = tp;
   request.magic = MAGICNUMBER;
}

// OK
/**
 * MACDがシグナル値に到達した瞬間に通知する。
 * サインを出すのは足が確定した後となるが、あらかじめ臨戦態勢に入っていないと遅れてしまうので
 * サイン発生前の予兆として使う。
 */
bool notifyOmen(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) {
   CopyBuffer(contextM5.macdHandle, 0, 0, 2, contextM5.macd);
   CopyBuffer(contextM5.macdHandle, 1, 0, 2, contextM5.signal);

   double macd_current = contextM5.macd[1]; // tickのMACD値。
   double macd_latest = contextM5.macd[0]; // 確定した最新のMACD値。

   double signal_current = contextM5.signal[1]; // tickのシグナル値。
   double signal_latest = contextM5.signal[0]; // 確定したのシグナル値。

   double h1dir = checkTrend(contextH1);

   bool ret = false;

   // MACDがシグナルを上方にブレイク
   if (checkUpperBreak(macd_current, macd_latest, signal_current, signal_latest)) {
      NOTIFY_MESSAGE(
         _CONFIG.eaName
         , StringFormat(
            "[INFO] MACDのシグナル上方ブレイク予兆が発生しました - macd: %f => %f, h1dir: %f"
            , macd_current
            , macd_latest
            , h1dir
           )
      );
      ret = true;
   }

   // MACDがシグナルを下方にブレイク
   if (checkLowerBreak(macd_current, macd_latest, signal_current, signal_latest)) {
      NOTIFY_MESSAGE(
         _CONFIG.eaName
         , StringFormat(
            "[INFO] MACDのシグナル下方ブレイク予兆が発生しました - macd: %f => %f, h1dir: %f"
            , macd_current
            , macd_latest
            , h1dir
            ));
      ret = true;
   }

   return ret;
}

/**
 * 利益が出ている場合の次のストップの値を計算する
 */
bool calcNextSL(double base, double current, double &nextSL, int &sign) {
   long type = -1;
   bool isTypeSuccess = PositionGetInteger(POSITION_TYPE, type);
   if (!isTypeSuccess) {
      return false;
   }
   bool isStopUpdatedRequired = false;
   sign = type == POSITION_TYPE_BUY ? 1 : -1;
   while (true) {
      double diff = -1; 
      if (type == POSITION_TYPE_BUY) {      
         diff = current - base;
      } else if (type == POSITION_TYPE_SELL) {
         diff = base - current;
      } else {
         return false;
      }
      //printf("[calcNextSL] current: %f, base: %f, diff: %f", current, base, diff);      
      if (diff > (_CONFIG.sl * 2)) {
         base = base + (sign * _CONFIG.sl);
         isStopUpdatedRequired = true;
      } else {
         break;
      }
   }
   nextSL = base;
   return isStopUpdatedRequired;
}

// OK
/**
 * 現在保持しているポジションを選択状態にする
 */
bool selectPosition() {
   // ポジションの情報を取得する
   // ポジション一覧のインデックス番号を指定して対応するポジションシンボルを取得
   // インデックス番号はポジションがひとつしかないことを前提にしているので0を指定する
   string symbol = PositionGetSymbol(0);
   if (StringLen(symbol) == 0) {
      return false;
   }
   return true;
}

// OK
/*
 * サブ足のMACDから現在のトレンドを判定する
 *
 * サブ足MACDの現在値と直近の確定値を比較し方向性を判断する。
 * (メイン足が先に転換するはずなのでトレンド転換時は基本ねじれるため転換直後はポジションを持たなくなる)
 */
double checkTrend(SimpleMACDContext &contextH1) {

   // 指標値を最新から2個分取る
   // [0]: 直近 ※最新の確定したローソク足(基本この値を見る)
   // [1]: 現在値 ※ローソク足が確定してないためまだ変動する
   CopyBuffer(contextH1.macdHandle, 0, 0, 2, contextH1.macd);

   double macd_current = contextH1.macd[1]; // tickのMACD値。
   double macd_latest = contextH1.macd[0]; // 確定した最新のMACD値。

   return macd_current - macd_latest;
}

// OK
/**
 * ポジションが存在しているかどうかを確認する
 */
bool isPositionExist() {
   bool hasPosition = false;
   int posCount = PositionsTotal();
   if (posCount == 1) {
      hasPosition = true;
   } else if (posCount == 0) {
      hasPosition = false;
   } else {
      // ポジションは同時に複数持たない方針であるため
      // ポジション数が1でも0でもない場合は何らかの不具合であるため即座に処理を終了させる
      ExpertRemove();
   }
   return hasPosition;
}

// OK
/**
 * 現在のtick値において利益がでているか確認する
 */
bool calcProfit(double &profit) {
   long type = -1;
   double openPrice = -1;
   double currentPrice = -1;
   bool result = false;
   bool isOpenPriceSuccess = GET_OPEN_PRICE(openPrice);
   bool isCurrentPriceSuccess = GET_CURRENT_PRICE(currentPrice);
   bool isTypeSuccess = PositionGetInteger(POSITION_TYPE, type);
   if (isOpenPriceSuccess && isCurrentPriceSuccess && isTypeSuccess) {
      if (type == POSITION_TYPE_BUY) {
         profit = currentPrice - openPrice;
      } else if (type == POSITION_TYPE_SELL) {
         profit = openPrice - currentPrice;
      }
      result = true;
   }
   POST_MESSAGE(_CONFIG.eaName, StringFormat("[calcProfit] profit: %f", profit));
   return result;
}

// OK
bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal) {
   if (new_macd >= old_macd
         && new_macd > new_signal
         && old_macd <= old_signal) {
      return true;
   }
   return false;
}

// OK
bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal) {
   if (new_macd <= old_macd
         && new_macd < new_signal
         && old_macd >= old_signal) {
      return true;
   }
   return false;
}
