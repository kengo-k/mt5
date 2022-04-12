// in Libraries/Custom/v1/common
#property library

const string API_PATH = "https://slack.com/api/chat.postMessage";
const string API_TOKEN = "xoxb-1575963846754-2351585442598-1sXQfrbugJpksBPHmtDJQcQQ";
const int timeout = 3000;

// TestModeの場合はSlackに通知しない
#define TestMode

int notifySlack(string message, string channel) export
{
#ifdef TestMode
   Print(message);
   return 0;
#else
   string requestHeaders;
   string responseHeaders;
   char request[];
   char response[];
   datetime current = TimeCurrent();
   string messageWithTime = StringFormat("%s [%s]", message, TimeToString(current, TIME_DATE | TIME_MINUTES));
   string reqString = StringFormat("token=%s&channel=%s&text=%s"
      , API_TOKEN
      , channel
      , messageWithTime
   );
   StringToCharArray(reqString, request, 0, -1, CP_UTF8);
   int retCode = WebRequest("POST"
      , API_PATH
      , requestHeaders
      , timeout
      , request
      , response
      , responseHeaders
   );
   //printf("web request result: %d", retCode);
   //printf("web request response: %s", responseHeaders);
   //printf("web response: %s", CharArrayToString(response));
   return retCode;
#endif
}
