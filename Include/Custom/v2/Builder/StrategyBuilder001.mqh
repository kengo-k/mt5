#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Common/Order.mqh>
#include <Custom/v2/Common/Util.mqh>

/**
 * 共通フレームワーク
 * ・新しいローソク足が生成されたタイミングでエントリ
 * ・任意のtickでクローズする
 */
template<typename CONFIG, typename CONTEXT>
class StrategyBuilder001 {
public:

   typedef void (*FnInitContext)(CONTEXT &contextMain, CONTEXT &contextSub, CONFIG &config);
   typedef void (*FnOpen)(CONTEXT &contextMain, CONTEXT &contextSub, CONFIG &t);
   typedef void (*FnClose)(CONTEXT &contextMain, CONTEXT &contextSub, CONFIG &t);

   StrategyBuilder001(
      CONFIG &_config
      , FnInitContext _fnInitContext
      , FnOpen _fnOpen
      , FnClose _fnClose
      , string _eaName
      , long _magicNumber
   ): fnInitContext(_fnInitContext)
      , fnOpen(_fnOpen)
      , fnClose(_fnClose)
      , barCount(-1)
      , eaName(_eaName)
      , magicNumber(_magicNumber) {
      this.config = _config;
   }

   void init() {
      this.fnInitContext(this.contextMain, this.contextSub, this.config);
   }

   void recvTick() {
      // ローソク足が新しく生成されているか数を確認
      int newBarCount = Bars(Symbol(), PERIOD_CURRENT);
      if (this.barCount == -1) {
         this.barCount = newBarCount;
      }

      // ポジションを保持している場合ティックの動きを監視して、利益がでている場合は確定する
      if (Util::hasPosition(this.magicNumber)) {
         this.fnClose(this.contextMain, this.contextSub, this.config);
      }

      // 新しい足が生まれた場合
      if (newBarCount > this.barCount) {
         this.barCount = newBarCount;
         this.fnOpen(this.contextMain, this.contextSub, this.config);
      }
   }

private:

   CONFIG config;
   CONTEXT contextMain;
   CONTEXT contextSub;
   int barCount;
   const FnOpen fnOpen;
   const FnClose fnClose;
   const FnInitContext fnInitContext;
   const string eaName;
   const long magicNumber;

};
