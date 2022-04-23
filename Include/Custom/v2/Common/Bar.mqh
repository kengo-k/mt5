class Bar {
public:

   typedef void (*FnProcess)();

   Bar(ENUM_TIMEFRAMES _period):
      count(-1),
      period(_period) {
   }

   void onBarCreated(FnProcess process) {
      // ローソク足が新しく生成されているか数を確認
      int newCount = Bars(Symbol(), this.period);
      if (this.count == -1) {
         this.count = newCount;
      }
      // 新しい足が生まれた場合
      if (newCount > this.count) {
         this.count = newCount;
         process();
      }
   }

private:
  int count;
  ENUM_TIMEFRAMES period;
};
