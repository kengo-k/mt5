// 日付関連ユーティリティクラス
class DateWrapper {
public:

   DateWrapper() {
      this.dateValue = TimeCurrent();
   }

   DateWrapper(datetime _dateValue) {
      this.dateValue = _dateValue;
   }

   string getYYYYMMDD() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat("%d%d%d", t.year, t.mon, t.day);
   }

   string getYYYYMM() {
      MqlDateTime t;
      TimeToStruct(this.dateValue, t);
      return StringFormat("%d%d", t.year, t.mon);
   }

private:
   datetime dateValue;
};
