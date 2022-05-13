/**
 * グリッドトレードバリエーション
 *
 * 目的: ヘッジロジックを単体で検証する
 *
 * 概要:
 * ・エントリ判定期間のMAとトレンド判定期間のMAで方向が一致した場合のみエントリする
 * ・トレンド転換の予兆が発生した時点で全てのポジションをクローズする
 *
 * 狙い:ひとまず最初のヘッジロジック検証ということでざっくりどんな成績になるかチェックする
 *
 * 結果:
 *  ①USDJPY,20110101-20211231,エントリ=M15,トレンド=D1, W1, MN1
 *   →MN1でトレンド継続中に残高大幅増。テスト終了間近に入りレンジに突入し、そこから微減。最終的には黒字で一応勝利
 *  D1: -40K
 *  W1: -40K
 *  MN1:+220K
 *
 *  ②USDJPY,20010101-20111231,エントリ=M15,トレンド=MN1 ※月足が基本だと判断しもう10年月足だけテスト
 *   →トレンド方向にかかわらず月足でトレンド継続があれば勝てると思っていたが全然勝てない
 *    エントリタイミングは間違ってなさそう。①と同程度にトレンドは継続しているのに決済に失敗している
 *  MN1:-86K
 *
 *  問題点:
 *  ・長期トレンドにのった場合、転換の予兆が出るまでポジションを持ち続けるので残高が伸びない期間が長期間継続する
 *  →最終的に別途短期で利益を積み上げていくストラテジーと組み合わせることで対応は可能と思われる
 *
 *  ・レンジ期間では勝てないため時期によっては残高が減少していく
 *  →レンジでも継続的に残高を増やせるストラテジーと組み合わせることで対応は可能であると思われる
 *
 *  ・長期の足を使うことでポジションを保持する数が増える。ポジションが増えるほどテスト実行時間が長くなり開発効率が下がってしまう
 *  →ちゃんと勝てるのであればもちろん何も問題はないがテスト実行に時間が割かれてしまうのはつらい。。
 *
 *  ・トレンド相場でもチャートの形によっては勝てない可能性がある・・・(※テスト②)
 *  →トレンド転換の予兆が出るまでにすでに大きな戻りが発生している場合に全決済をしてしまうと大きな損失になってしまう模様
 *
 * 総評:
 *  ①トレンド判定はより長い足を使うほうが有効であるように思える
 *  　短い足を使うと頻繁にトレンド転換を検知してしまい損失を抱えたままの決済が多発するため
 *   →ただし勝利するためには長期トレンドが(良い形で)きてくれることが前提であるため来なければ必ず敗北する。ギャンブル性が強い
 *
 *  ②短期で多数の決済をして利益を積み上げるストラテジーがあればレンジ中の損失を埋め合わせつつ長期トレンドのチャンスを待つことができるため
 *  　そこから大きな利益を上げることができるのではないかという希望がある。
 *
 * 今後の展望
 * ・検討の余地はあるがこのままでは本番採用はできない。
 * ・トレンド転換の予兆を待ってから決済では(チャートの動きによるが)勝てるかどうかが怪しいため方式の変更が必要か
 * ・何からの基準を満たした時点(一定の利益/一定の期間etc)でトレンド転換予兆を待たずして決済する方法を検討してみるとよいかもしれない
 */
#include <Custom/v2/Strategy/GridStrategy/01/StrategyTemplate.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Config.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICheckTrend.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IGetEntryCommand.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/ICloseHedgePositions.mqh>

// 以下固有ロジック提供するためのIF実装をincludeする
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CheckTrend/CheckTrend2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/GetEntryCommand/GetEntryCommand2maFast1.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/Logic/CloseHedgePositions/CloseHedgePositionsOnlyWhenTrendSwitch1.mqh>

// エントリ時間足(たぶん固定)
input ENUM_TIMEFRAMES CREATE_ORDER_TIMEFRAME = PERIOD_M15;

// トレンド判定時間足(たぶん固定)
input ENUM_TIMEFRAMES HEDGE_DIRECTION_TIMEFRAME = PERIOD_MN1;

// エントリ判定短期MA期間(最適化余地あり)
input int ORDER_MA_PERIOD = 5;

// エントリ判定長期MA期間(最適化余地あり)
input int ORDER_LONG_MA_PERIOD = 15;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_MA_PERIOD = 5;

// トレンド判定短期MA期間(最適化余地あり)
input int HEDGE_LONG_MA_PERIOD = 15;

// ヘッジ用グリッドサイズ
input int HEDGE_GRID_SIZE = 10;

// 以下global変数に値を設定する
string EA_NAME = "gridstrategy01-05";
Logger *__LOGGER__ = new Logger(EA_NAME, LOG_LEVEL_INFO);
bool USE_GRID_TRADE = false;
bool USE_GRID_HEDGE_TRADE = true;

Config __config__(
   -1//TP
   , -1//TOTAL_HEDGE_TP
   , CREATE_ORDER_TIMEFRAME
   , PERIOD_M1
   , HEDGE_DIRECTION_TIMEFRAME
   , ORDER_MA_PERIOD
   , ORDER_LONG_MA_PERIOD
   , HEDGE_MA_PERIOD
   , HEDGE_LONG_MA_PERIOD
   , -1//ORDER_GRID_SIZE
   , HEDGE_GRID_SIZE
);
Config *__config = &__config__;

CheckTrend __checkTrend__;
ICheckTrend *__checkTrend = &__checkTrend__;

GetEntryCommand __getEntryCommand__;
IGetEntryCommand *__getEntryCommand = &__getEntryCommand__;

CloseHedgePositions __closeHedgePositions__;
ICloseHedgePositions *__closeHedgePositions = &__closeHedgePositions__;
