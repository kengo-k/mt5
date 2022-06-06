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
      return StringFormat("%d%d", t.year, t.mon);
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
      return StringFormat("%d%d%d", t.year, t.mon, t.day);
   }

   string getYYYYMMDDHH() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat("%d%d%d%d", t.year, t.mon, t.day, t.hour);
   }

private:
   datetime dateValue;
};
