/**
 * ContextとConfigの型を特定したOpen/Close処理をパッケージングする処理
 */
#include <Custom/v2/Common/Constant.mqh>
#include <Custom/v2/Config/Config001.mqh>
#include <Custom/v2/Context/Context001.mqh>
#include <Custom/v2/Logic/Open/Open001.mqh>

typedef void (*FnOpen)(Context001 &contextMain, Context001 &contextSub, Config001 &t);
typedef void (*FnClose)(Context001 &contextMain, Context001 &contextSub, Config001 &t);

struct Logic {
   FnOpen fnOpen;
   FnClose fnClose;
};

class LogicFactory {
public:
   Logic createLogic() {
      Logic logic;
      logic.fnOpen = open;
      logic.fnClose = close;
      return logic;
   }
};

void open(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
   Open001::open(contextMain, contextSub, config);
}

void close(Context001 &contextMain, Context001 &contextSub, Config001 &config) {
}
