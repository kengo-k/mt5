class Bar {
public:

   typedef void (*FnProcess)();

   Bar():
      count(-1),
      timeframes(PERIOD_CURRENT) {
   }

   void onBarCreated(FnProcess process) {
      // ローソク足が新しく生成されているか数を確認
      int newCount = Bars(Symbol(), this.timeframes);
      if (this.count == -1) {
         this.count = newCount;
      }
      // 新しい足が生まれた場合
      if (newCount > this.count) {
         this.count = newCount;
         process();
      }
   }

   void setTimeframes(ENUM_TIMEFRAMES _timeframes) {
      this.timeframes = _timeframes;
   }

private:
  int count;
  ENUM_TIMEFRAMES timeframes;
};
