// Include/Custom/SlackLib.mqh
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#define NOTIFY_MESSAGE(EA_NAME, message) notifySlack(StringFormat("<!channel> %s", message), EA_NAME);
#define POST_MESSAGE(EA_NAME, message) notifySlack(StringFormat("%s", message), EA_NAME);
