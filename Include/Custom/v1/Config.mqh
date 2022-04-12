// in Include/Custom/v1
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Custom/v1/Context.mqh>

enum ENUM_ENTRY_COMMAND {
   ENTRY_COMMAND_BUY
   ,ENTRY_COMMAND_SELL
   ,ENTRY_COMMAND_NOOP
};

typedef ENUM_ENTRY_COMMAND (*FnOpen)(Context&, Context&);
typedef void (*FnClose)(Context&, Context&);

/**
 * カスタマイズ用のパラメータ構造体
 */
struct Config {
   // 動作させているEAの名前
   string eaName;
   
   // ストップ幅(pips)
   double sl;
   // 利益確定幅
   double tp;
   
   //
   // トレール用設定
   //
   
   // この価格にきたら最初のストップを動かし利益確定状態とする目標価格(pips)
   double firstProfitTarget;
   // firstProfitTargetに到達したときにstopをどれだけ動かすかを示す値(pips)
   double firstProfitValue;
   // 利益確定後のトレール幅(pips)
   double trailValue;
   
   // 利益確定の基準(倍率)
   // ストップ幅に指定された値*ここで指定された値だけ利益が出た段階でストップをストップ幅だけ切り上げる
   int tpRatio;
   // 取引量
   double volume;
   // 短期MA期間
   int shortMaPeriod;   
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
   // MACD期間
   int macdPeriod[3];
   // MACDによるエントリタイミングのフィルタとして使用するMACD値の敷居値
   double macdThreshold;
   // サブ足(方向性を特定するための足。フィルターとして使う)
   ENUM_TIMEFRAMES subPeriod;
   // ポジションを建てるロジック
   FnOpen open;
   // ポジションを決済するロジック
   FnClose close;
   // マジックナンバー
   long MAGIC_NUMBER;
};