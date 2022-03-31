// Libraries/Custom/Logics/NotifySlack.mq5
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
#include <Custom/SimpleMACDContext.mqh>

#import "Custom/Apis/NotifySlack.ex5"
  int notifySlack(string message, string channel);
#import


// このEAの名前
string _EA_NAME;
// 使用通貨。ドル円固定
string _TARGET_SYMBOL;

double _TARGET_STOP;
double _TARGET_LIMIT;
double _TARGET_TRAIL;

// 予兆の通知済みフラグ
bool isOmenNotified;

// 建玉を保持しているかどうか
bool hasPosition;
// 利益が確定されているかどうか
bool isProfitFixed;

// 成り行き注文のリクエストを生成する
void initOrderReq(
   MqlTradeRequest &request
   , ENUM_ORDER_TYPE type // BUY/SELL
   , ENUM_SYMBOL_INFO_DOUBLE symbol // ASK/BID
   , double sl
   , double tp
   , double volume
) {
   double price = SymbolInfoDouble(_TARGET_SYMBOL, symbol);
   request.action = TRADE_ACTION_DEAL; // 注文タイプ：　成行
   request.type = type;
   request.symbol = _TARGET_SYMBOL;
   request.volume = volume; // 注文数量(ロット) 0.1 = 10000;
   request.price = SymbolInfoDouble(_TARGET_SYMBOL, symbol);
   request.sl = price + sl; // ストップ

   // リミットをいれるかどうかは要検討
   // 利益を伸ばしたいのでティック監視してストップを切り上げていくほうがよいのではないかと考えている
   request.tp = price + tp; // リミット

   request.deviation = 3; // スリッページ
   request.expiration = ORDER_TIME_DAY; // 有効期限
   request.comment = ""; // 任意のコメント
   request.magic = 123456; // NOTE EAのポジションを一意に識別するための番号
}

#define INIT_ORDER_BUY(request, sl, tp, volume) initOrderReq(request, ORDER_TYPE_BUY, SYMBOL_ASK, -sl, +tp, volume);
#define INIT_ORDER_SELL(request, sl, tp, volume) initOrderReq(request, ORDER_TYPE_SELL, SYMBOL_BID, +sl, -tp, volume);

void SimpleMACD_Configure(
   string EA_NAME,
   string TARGET_SYMBOL,
   double TARGET_STOP,
   double TARGET_LIMIT,
   double TARGET_TRAIL
) export {
   _EA_NAME = EA_NAME;
   _TARGET_SYMBOL = TARGET_SYMBOL;
   _TARGET_STOP = TARGET_STOP;
   _TARGET_LIMIT = TARGET_LIMIT;
   _TARGET_TRAIL = TARGET_TRAIL;
   NOTIFY_MESSAGE(_EA_NAME, StringFormat("start %s. %s", _EA_NAME, "M5/H1"));
}

void SimpleMACD_Init(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) export {

   contextM5.macdHandle = iMACD(_TARGET_SYMBOL, PERIOD_M5, 12, 26, 9, PRICE_CLOSE);
   contextM5.barCount = -1;
   contextH1.macdHandle = iMACD(_TARGET_SYMBOL, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);

   hasPosition = false;
   isProfitFixed = false;
   isOmenNotified = false;

   // 基本方針: ポジションを複数持つことはしない=ポジションをすでにもっているときは
   // 追加の注文は行わないようにするため初期起動時にポジションが存在することを確認する。
   // → PositionsTotal()で未決済ポジションの数を返せる。これが0より大きければポジション保持済み
   //
   // ただしプログラムが建てたポジションと手動で建てたポジションを混同したくないので別途対策が必要かもしれない
   // (MT5で手動することは多分ないとは思うが)
   //
   // 保持済みのポジションに関する各種情報を取得するには、上記関数で取得したポジション数でループして
   // PostionGetInteger()やPositionGetString()などにほしいプロパティのENUMを指定して参照経由で取得する
   // ポジションが手動かプログラムによるものかは上記のENUMで取得できる情報から判別できる
   // ENUM_POSITION_REASON.POSITION_REASON_EXPERTの場合はプログラムにより建てられたポジション
   // ※当面は手動でポジションを建てないので上記の対策は実装しない

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

   if (hasPosition) {
      selectPosition();
      // 利益計算をするためポジション価格と現在価格を取得する
      double positionPrice = getPositionPrice();
      double slPrice = getStopPrice();
      long positionType = PositionGetInteger(POSITION_TYPE);
      bool hasProfit = false;
      if (positionType == POSITION_TYPE_BUY) {
         hasProfit = (slPrice > positionPrice);
      } else if (positionType == POSITION_TYPE_SELL) {
         hasProfit = (slPrice < positionPrice);
      } else {
         ExpertRemove();
      }
      isProfitFixed = hasProfit;
   }
}

void SimpleMACD_OnTick(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) export {
   int newM5BarCount = Bars(_TARGET_SYMBOL, PERIOD_M5);
   if (contextM5.barCount == -1) {
      contextM5.barCount = newM5BarCount;
   }

   // 予兆の通知
   // ポジションを持っている場合は通知する必要はないが一応注意を促しておいたほうがいいため通知だけはする
   // ただし無制限に出すと通知があふれるため同じ足の中で一度だけ出す
   if (!isOmenNotified) {
      isOmenNotified = SimpleMACD_CheckOmen(contextM5, contextH1);
   }

   // ポジションを保持している場合ティックの動きを監視して、利益がでている場合はストップを移動させて利益を確定させる
   if (hasPosition) {
      selectPosition();
      double currentPrice = getCurrentPositionPrice();
      double stopPrice = getStopPrice();
      double basePrice;
      if (isProfitFixed) {
         basePrice = stopPrice;
      } else {
         basePrice = getPositionPrice();
      }
      // tickの値が一気に飛ぶ場合があるので条件を満たす範囲で上げられる限界までストップの値を上げる
      while (true) {
         if (currentPrice > basePrice + (_TARGET_TRAIL * 2)) {
            basePrice = basePrice + _TARGET_TRAIL;
         } else {
            break;
         }
      }
      // ストップの更新が可能な場合ポジションのストップを更新する
      if (basePrice > stopPrice) {

      }
   }

   // 新しい足が生まれた場合
   if (newM5BarCount > contextM5.barCount) {
      contextM5.barCount = newM5BarCount;
      SimpleMACD_CheckNewBar(contextM5, contextH1);
      // 通知済みフラグをリセット
      isOmenNotified = false;
   }
}

void selectPosition() {
   // ポジションの情報を取得する
   // ポジション一覧のインデックス番号を指定して対応するポジションシンボルを取得
   // インデックス番号はポジションがひとつしかないことを前提にしているので0を指定する
   string symbol = PositionGetSymbol(0);
   // 指定したポジションを選択状態にする
   // 失敗した場合は処理を終了する
   if (!PositionSelect(symbol)) {
      ExpertRemove();
   }
}

// 建玉の約定価格を取得する
double getPositionPrice() {
   double positionPrice;
   if (!PositionGetDouble(POSITION_PRICE_OPEN, positionPrice)) {
      ExpertRemove();
   }
   return positionPrice;
}

// 建玉のストップ価格を取得する
double getStopPrice() {
   double slPrice;
   if (!PositionGetDouble(POSITION_SL, slPrice)) {
      ExpertRemove();
   }
   return slPrice;
}

// ポジションの現在価格を取得する
double getCurrentPositionPrice() {
   double currentPrice;
   if (!PositionGetDouble(POSITION_PRICE_CURRENT, currentPrice)) {
      ExpertRemove();
   }
   return currentPrice;
}


/**
 * MACDがシグナル値に到達した瞬間に通知する。
 * サインを出すのは足が確定した後となるが、あらかじめ臨戦態勢に入っていないと遅れてしまうので
 * サイン発生前の予兆として使う。
 */
bool SimpleMACD_CheckOmen(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) {
   CopyBuffer(contextM5.macdHandle, 0, 0, 2, contextM5.macd);
   CopyBuffer(contextM5.macdHandle, 1, 0, 2, contextM5.signal);

   double macd_current = contextM5.macd[1]; // tickのMACD値。
   double macd_latest = contextM5.macd[0]; // 確定した最新のMACD値。

   double signal_current = contextM5.signal[1]; // tickのシグナル値。
   double signal_latest = contextM5.signal[0]; // 確定したのシグナル値。

   double h1dir = SimpleMACD_CheckH1Trend(contextH1);

   bool ret = false;

   // MACDがシグナルを上方にブレイク
   if (checkUpperBreak(macd_current, macd_latest, signal_current, signal_latest)) {
      NOTIFY_MESSAGE(
         _EA_NAME
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
         _EA_NAME
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
 * M5の足が生成されたときにMACDのサインが出た場合に通知する
 */
void SimpleMACD_CheckNewBar(SimpleMACDContext &contextM5, SimpleMACDContext &contextH1) {

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

   double h1dir = SimpleMACD_CheckH1Trend(contextH1);
   int digits = Digits();

   // 元から正規化されてるから多分Normalizeしなくてもよさそう
   // 取得した値になんらかの加工した場合にすればよさそう
   double ask = NormalizeDouble(SymbolInfoDouble(_TARGET_SYMBOL, SYMBOL_ASK), digits);
   double bid = NormalizeDouble(SymbolInfoDouble(_TARGET_SYMBOL, SYMBOL_BID), digits);
   double spread = NormalizeDouble(ask - bid, digits);

   // 新しい足が生成されたログを表示
   POST_MESSAGE(
      _EA_NAME
      , StringFormat(
         "new bar was created, macd: %f, signal: %f, h1dir: %f, bid: %s, ask: %s, spread: %f"
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

   int posCount = PositionsTotal();
   if (posCount > 0) {
      // ストップが移動されたかどうかを判定する
      // 買いの場合、ストップ価格 > 約定価格(売りは逆)であればストップが移動されたと判断できる
      bool stopMoved = false;

      // 損失があるかどうかはprofitの値を見る
      double profit;

      bool isPositionKeeped = profit < 0 || stopMoved;
      // ポジションキープではない場合は決済する
      if (!isPositionKeeped) {
         // 決済する場合はOrderSendに既存のチケット番号を指定することで反対売買となる
         // (両建て可能口座の場合のみ。両建てNG口座の場合はチケット指定は不要)

      }
   } else {

      // 新規注文

      // MACDがシグナルを上方にブレイク
      if (checkUpperBreak(macd_latest, macd_prev, signal_latest, signal_prev) && h1dir > 0) {
         NOTIFY_MESSAGE(
            _EA_NAME
            , StringFormat(
               "[INFO] MACDがシグナルを上方ブレイクしました - stop: %s, limit: %s"
               , DoubleToString(NormalizeDouble(bid - _TARGET_STOP, digits), digits)
               , DoubleToString(NormalizeDouble(bid + _TARGET_LIMIT, digits), digits)
              )
         );

         // 注文送信
         MqlTradeRequest request = {};
         MqlTradeResult result = {};
         INIT_ORDER_BUY(request, _TARGET_STOP, _TARGET_LIMIT, 0.1);
         bool isSended = OrderSend(request, result);

         // 注文の送信に失敗した場合なんらかのバグの可能性があるのでEAを停止させる
         // ※送信に成功しただけであってポジションが正常に生成されたことを保証するわけではないので注意
         if (!isSended) {
            ExpertRemove();
         }

         // 正常に処理が続行しているかを判定する必要があるかどの項目をどう判定すべきかわかってないのでとりあえずログだけ出しとく
         NOTIFY_MESSAGE(
            _EA_NAME,
            StringFormat(
               "order sended - request_id: %d, retcode: %d, retcode_external: %d, deal: %d, order: %d, "
               , result.request_id
               , result.retcode
               , result.retcode_external
               , result.deal
               , result.order
            )
         );

         // TODO retcode等を参照し処理を続行できない状態であればEAを停止させる
         // ※ひとまず成功前提にしておく
         hasPosition = true;
      }

      // MACDがシグナルを下方にブレイク
      if (checkLowerBreak(macd_latest, macd_prev, signal_latest, signal_prev) && h1dir < 0) {
         NOTIFY_MESSAGE(
            _EA_NAME
            , StringFormat(
               "[INFO] MACDがシグナルを下方ブレイクしました - stop: %s, limit: %s"
               , DoubleToString(NormalizeDouble(ask + _TARGET_STOP, digits), digits)
               , DoubleToString(NormalizeDouble(ask - _TARGET_LIMIT, digits), digits)
              )
         );
      }
   }
}

/*
 * H1のMACDから現在のトレンドを判定
 *
 * H1のMACD現在値と直近の確定値を比較し方向性を判断する
 * 方向性の判定はtick更新毎に行う
 * (M5のほうが先に転換するはずなのでトレ転時は基本捻じれてしまうためなるべく新しい方向性を取得したいため)
 */
double SimpleMACD_CheckH1Trend(SimpleMACDContext &contextH1) {

   // 指標値を最新から2個分取る
   // [0]: 直近 ※最新の確定したローソク足(基本この値を見る)
   // [1]: 現在値 ※ローソク足が確定してないためまだ変動する
   CopyBuffer(contextH1.macdHandle, 0, 0, 2, contextH1.macd);

   double macd_current = contextH1.macd[1]; // tickのMACD値。
   double macd_latest = contextH1.macd[0]; // 確定した最新のMACD値。

   printf("current: %f, latest: %f", macd_current, macd_latest);
   return macd_current - macd_latest;
}

bool checkUpperBreak(double new_macd, double old_macd, double new_signal, double old_signal) {
   if (new_macd >= old_macd
         && new_macd > new_signal
         && old_macd <= old_signal) {
      return true;
   }
   return false;
}

bool checkLowerBreak(double new_macd, double old_macd, double new_signal, double old_signal) {
   if (new_macd <= old_macd
         && new_macd < new_signal
         && old_macd >= old_signal) {
      return true;
   }
   return false;
}
