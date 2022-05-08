#include <Generic/ArrayList.mqh>
#include <Custom/v2/Common/Logger.mqh>
#include <Custom/v2/Common/Request.mqh>

/**
 * 注文を管理するデータコンテナ
 */
class RequestContainer {
public:

   static Request* createRequest() {
      static ulong seq = 1;
      Request *req = new Request();
      req.requestId = seq;
      seq++;
      return req;
   }

   void add(Request *request) {
      LoggerFacade logger;
      logger.logDebug(StringFormat("create request #%d", request.requestId));
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
