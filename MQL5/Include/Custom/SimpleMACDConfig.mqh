// Include/Custom/SimpleMACDConfig.mqh
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

/**
 * カスタマイズ用のパラメータ構造体
 */
struct SimpleMACDConfig {
   // 動作させているEAの名前
   string eaName;
   // 対象の通貨ペア
   string symbol;
   // ストップ幅
   double sl;
   // 取引量
   double volume;
   // メイン足
   ENUM_TIMEFRAMES mainPeriod;
   // サブ足(方向性を特定するための足。フィルターとして使う)
   ENUM_TIMEFRAMES subPeriod;
   // サブ足によるフィルターを有効にするかどうか
   bool isFilterEnabled;
};
