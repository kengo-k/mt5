// strategy001用Config
class Config {
public:
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
