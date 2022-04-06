// Include/Custom/SimpleMACDContext.mqh
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

struct Context {
   int macdHandle;
   double macd[];
   double signal[];
   int barCount;
};
