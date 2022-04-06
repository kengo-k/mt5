// Include/Custom/SimpleMACDConfig.mqh
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Custom/SimpleMACDContext.mqh>


enum ENUM_ENTRY_COMMAND {
   ENTRY_COMMAND_BUY
   ,ENTRY_COMMAND_SELL
   ,ENTRY_COMMAND_NOOP
};

typedef ENUM_ENTRY_COMMAND (*FnCreateCommand)(SimpleMACDContext&);
typedef bool (*FnCommandFilter)(ENUM_ENTRY_COMMAND, SimpleMACDContext&, SimpleMACDContext&);
typedef void (*FnExec)(SimpleMACDContext&, SimpleMACDContext&);

/**
 * カスタマイズ用のパラメータ構造体
 */
struct SimpleMACDConfig {
   // 動作させているEAの名前
   string eaName;
   // ストップ幅(pips)
   double sl;
   // 1pipsあたりの単位
   double unit;
   // 利益確定の基準(倍率)
   // ストップ幅に指定された値*ここで指定された値だけ利益が出た段階でストップをストップ幅だけ切り上げる
   int tpRatio;
   // 取引量
   double volume;
   // メイン足
   ENUM_TIMEFRAMES mainPeriod;
   // サブ足(方向性を特定するための足。フィルターとして使う)
   ENUM_TIMEFRAMES subPeriod;
   // メイン足によるエントリフィルタ
   FnCreateCommand createCommand;
   // サブ足によるエントリフィルタ
   FnCommandFilter filterCommand;
   // 保有ポジションを監視する処理
   // ストップを更新するとか利益確定する等任意の処理を入れる
   FnExec observe;
   // マジックナンバー
   long MAGIC_NUMBER;
};