// 許容スプレッド計算用インターフェース
interface ISpreadCalculator {
   // スプレッド制限を有効にするかどうか
   bool isEnabled();

   // 許容できる最大スプレッドを取得する
   int getMaxSpread();

   string toString();
};

class NoopSpreadCalculator : public ISpreadCalculator {
public:
   bool isEnabled() {
      return false;
   }

   int getMaxSpread() {
      return -1;
   }

   string toString() {
      return "";
   }
};

// 固定値のスプレッドを返すCalculator
class FixedSpreadCalculator : public ISpreadCalculator {
public:

   FixedSpreadCalculator(int _spread)
      : spread(_spread) {}

   bool isEnabled() {
      return true;
   }

   int getMaxSpread() {
      return this.spread;
   }

   string toString() {
      return StringFormat("%d", this.spread);
   }

private:
   int spread;

};
