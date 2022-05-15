#include <Custom/v2/Common/LogId.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Strategy/GridStrategy/01/IObserve.mqh>

// 残高と証拠金をログに記録する
class AccountObserver : public IObserver {
public:

   void exec() {
      int balance = (int) AccountInfoDouble(ACCOUNT_BALANCE);
      int marginFree = (int) AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if (balance > this.maxAccountBalance) {
         this.maxAccountBalance = balance;
      }
      LOG_DEBUG_WITH_ID(StringFormat("account: balance=%d, margin free=%d", balance, marginFree), LOGID_ACCOUNT);
   }

   void logTotalReport() {
      LOG_DEBUG_WITH_ID("---------- total account report ----------", LOGID_ACCOUNT_TOTAL);
      LOG_DEBUG_WITH_ID(StringFormat("  max account balance: %d", this.maxAccountBalance), LOGID_ACCOUNT_TOTAL);
   }

   int maxAccountBalance;
};
