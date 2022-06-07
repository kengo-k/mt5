#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Util.mqh>
#include <Custom/v2/Common/DateWrapper.mqh>

#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

// EAが稼働していることを一定間隔で通知する。
// ついでに口座情報等も併せて記載する。
class HealthCheckNotifier : public IObserver {
public:

   void exec() {
      DateWrapper date = new DateWrapper(Util::getJpTime());
      int h = date.getHour();
      if (h == 8 || h == 12 || h == 16 || h == 20 || h == 0) {
         int balance = (int) AccountInfoDouble(ACCOUNT_BALANCE);
         int freeMargin = (int) AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         int posCount = PositionsTotal();
         string message = StringFormat("[HEALTHCHECK] balance: %d, free margin: %d, position count: %d", balance, freeMargin, posCount);
         NOTIFY(message, false, true);
      }
   }
};
