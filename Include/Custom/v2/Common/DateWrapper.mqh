// 日付関連ユーティリティクラス
class DateWrapper {
public:

   DateWrapper() {
      this.dateValue = TimeCurrent();
   }

   DateWrapper(datetime _dateValue) {
      this.dateValue = _dateValue;
   }

   string getYYYYMM() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat("%d%02d", t.year, t.mon);
   }

   int getWeek() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return t.day_of_week;
   }

   int getHour() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return t.hour;
   }

   string getYYYYMMDD() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat("%d%02d%02d", t.year, t.mon, t.day);
   }

   string getYYYYMMDDHH() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat("%d%02d%02d%02d", t.year, t.mon, t.day, t.hour);
   }

   string getYYYYMMDDHHMMSS(string format = "%d%02d%02d%02d") {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat(format, t.year, t.mon, t.day, t.hour, t.min, t.sec);
   }

private:
   datetime dateValue;
};
