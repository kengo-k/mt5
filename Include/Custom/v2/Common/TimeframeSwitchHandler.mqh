#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/DateWrapper.mqh>

// 期間の切り替わりを検知する処理
class TimeframeSwitchHandler {
public:

   void set(ENUM_TIMEFRAMES _timeframes) {
      this.timeframes = _timeframes;
      this.latest = this.getInitialMaxDate();
   }

   // 期間更新処理
   void update() {
      string current = this.getCurrentDate();
      this.prev = this.latest;
      this.latest = current;
   }

   bool isSwitched() {
      return this.latest != this.prev;
   }

   string getCurrentDate() {

      string ret = "";
      DateWrapper date;
      if (this.timeframes == PERIOD_MN1) {
         ret = date.getYYYYMM();
      } else if (this.timeframes == PERIOD_W1) {
         ret = StringFormat("%d", date.getWeek());
      } else if (this.timeframes == PERIOD_D1) {
         ret = date.getYYYYMMDD();
      } else if (this.timeframes == PERIOD_H1) {
         ret = date.getYYYYMMDDHH();
      } else {
         LOG_ERROR(StringFormat("Unsupported timeframes: %d", this.timeframes));
         ExpertRemove();
      }
      return ret;
   }

   string getInitialMaxDate() {
      string ret = "";
      if (this.timeframes == PERIOD_MN1) {
         ret = MAX_YYYYMM;
      } else if (this.timeframes == PERIOD_W1) {
         ret = "9";
      } else if (this.timeframes == PERIOD_D1) {
         ret = MAX_YYYYMMDD;
      } else if (this.timeframes == PERIOD_H1) {
         ret = MAX_YYYYMMDDHH;
      } else {
         LOG_ERROR(StringFormat("Unsupported timeframes: %d", this.timeframes));
         ExpertRemove();
      }
      return ret;
   }

private:
   ENUM_TIMEFRAMES timeframes;
   string latest;
   string prev;
};
