// strategy001用Config
class Config {
public:
   
   Config(
      double _tp
      ,double _totalHedgeTp
      ,ENUM_TIMEFRAMES _createOrderTimeframe
      ,ENUM_TIMEFRAMES _sendOrderTimeframe
      ,ENUM_TIMEFRAMES _hedgeDirectionTimeframe
      ,int _orderMaPeriod
      ,int _orderLongMaPeriod
      ,int _hedgeMaPeriod
      ,int _hedgeLongMaPeriod
      ,int _orderGridSize
      ,int _hedgeGridSize
   ): 
      tp(_tp)
      , totalHedgeTp(_totalHedgeTp)
      , createOrderTimeframe(_createOrderTimeframe)
      , sendOrderTimeframe(_sendOrderTimeframe)
      , hedgeDirectionTimeframe(_hedgeDirectionTimeframe)
      , orderMaPeriod(_orderMaPeriod)
      , orderLongMaPeriod(_orderLongMaPeriod)
      , hedgeMaPeriod(_hedgeMaPeriod)
      , hedgeLongMaPeriod(_hedgeLongMaPeriod)      
      , orderGridSize(_orderGridSize)
      , hedgeGridSize(_hedgeGridSize) 
   {}
   
   double tp;
   double totalHedgeTp;
   ENUM_TIMEFRAMES createOrderTimeframe;
   ENUM_TIMEFRAMES sendOrderTimeframe;
   ENUM_TIMEFRAMES hedgeDirectionTimeframe;
   int orderMaPeriod;
   int orderLongMaPeriod;
   int hedgeMaPeriod;
   int hedgeLongMaPeriod;
   int orderGridSize;
   int hedgeGridSize;
};
