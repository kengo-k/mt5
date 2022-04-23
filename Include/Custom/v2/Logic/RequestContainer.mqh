#include <Generic/ArrayList.mqh>

class Request {
public:
   MqlTradeRequest item;
};

/**
 * 注文を管理するデータコンテナ
 */
class RequestContainer {
public:
   
   static Request* createRequest() {
      return new Request();
   }

   void add(Request *request) {
      this.queue.Add(request);
   }

   int count() {
      return this.queue.Count();
   }

   Request* get(int index) {
      Request* request;
      this.queue.TryGetValue(index, request);
      return request;
   }

   bool remove(int index) {
      if (this.queue.Count() > 0) {
         Request *request;
         this.queue.TryGetValue(index, request);
         this.queue.RemoveAt(index);
         delete request;
         return true;
      } else {
         return false;
      }
   }   
   
private:
   CArrayList<Request*> queue;
};
