#include <Custom/v2/Common/Constant.mqh>

// GridStrategy用のConfig
class Config {
public:

   Config(
      int _tp
      ,int _hedgeTp
      ,ENUM_HEDGE_TP_MODE _hedgeTpMode
      ,ENUM_TIMEFRAMES _createOrderTimeframe
      ,ENUM_TIMEFRAMES _sendOrderTimeframe
      ,ENUM_TIMEFRAMES _hedgeDirectionTimeframe
      ,ENUM_TIMEFRAMES _observeTimeframe
      ,int _orderMaPeriod
      ,int _orderLongMaPeriod
      ,int _hedgeMaPeriod
      ,int _hedgeLongMaPeriod
      ,int _orderGridSize
      ,int _hedgeGridSize
      ,bool _useGridTrade
      ,bool _useGridHedgeTrade
      ,ENUM_GRID_HEDGE_MODE _gridHedgeMode
      ,bool _buyable
      ,bool _sellable
      ,bool _isIncludeSwap
      ,ENUM_VOLUME_SETTINGS _volumeSettings
      ,int _maxSpread
   ):
      tp(_tp)
      , hedgeTp(_hedgeTp)
      , hedgeTpMode(_hedgeTpMode)
      , createOrderTimeframe(_createOrderTimeframe)
      , sendOrderTimeframe(_sendOrderTimeframe)
      , hedgeDirectionTimeframe(_hedgeDirectionTimeframe)
      , observeTimeframe(_observeTimeframe)
      , orderMaPeriod(_orderMaPeriod)
      , orderLongMaPeriod(_orderLongMaPeriod)
      , hedgeMaPeriod(_hedgeMaPeriod)
      , hedgeLongMaPeriod(_hedgeLongMaPeriod)
      , orderGridSize(_orderGridSize)
      , hedgeGridSize(_hedgeGridSize)
      , useGridTrade(_useGridTrade)
      , useGridHedgeTrade(_useGridHedgeTrade)
      , gridHedgeMode(_gridHedgeMode)
      , buyable(_buyable)
      , sellable(_sellable)
      , isIncludeSwap(_isIncludeSwap)
      , volumeSettings(_volumeSettings)
      , maxSpread(_maxSpread)
   {}

   int tp;
   int hedgeTp;
   ENUM_HEDGE_TP_MODE hedgeTpMode;
   ENUM_TIMEFRAMES createOrderTimeframe;
   ENUM_TIMEFRAMES sendOrderTimeframe;
   ENUM_TIMEFRAMES hedgeDirectionTimeframe;
   ENUM_TIMEFRAMES observeTimeframe;
   int orderMaPeriod;
   int orderLongMaPeriod;
   int hedgeMaPeriod;
   int hedgeLongMaPeriod;
   int orderGridSize;
   int hedgeGridSize;
   bool useGridTrade;
   bool useGridHedgeTrade;
   ENUM_GRID_HEDGE_MODE gridHedgeMode;
   bool buyable;
   bool sellable;
   bool isIncludeSwap;
   double gridVolume;
   double hedgeVolume;
   ENUM_VOLUME_SETTINGS volumeSettings;
   int maxSpread;
};
