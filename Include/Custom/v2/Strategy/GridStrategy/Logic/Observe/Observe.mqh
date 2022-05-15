#include <Generic/ArrayList.mqh>
#include <Custom/v2/Strategy/GridStrategy/IObserve.mqh>

// 監視処理実装
class Observe : public IObserve {
public:

   Observe(
      CArrayList<IObserver*> *_observerList
   )
      : observerList(_observerList) {}

   void exec() {
      int count = this.observerList.Count();
      for (int i = 0; i < count; i++) {
         IObserver *observer;
         this.observerList.TryGetValue(i, observer);
         observer.exec();
      }
   }

private:
   CArrayList<IObserver*> *observerList;
};
