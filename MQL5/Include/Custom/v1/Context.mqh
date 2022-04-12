// in Include/Custom/v1
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

struct Context {
   int shortMaHandle;
   int longMaHandle;
   int longlongMaHandle;
   int macdHandle;
   double shortMA[];
   double longMA[];
   double longlongMA[];
   double macd[];
   double signal[];
   int barCount;
};
