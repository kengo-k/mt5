struct Config004 {
   // 動作させているEAの名前
   string eaName;
   // どのEAによるポジションかを識別するための番号
   long magicNumber;
   // 取引量
   double volume;
   // 利益目標(pips)
   double tp;   
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
   // グリッドの大きさ(pips)
   int gridSize;
   // 発注に使用する時間足
   ENUM_TIMEFRAMES orderPeriod;
};

class Config004Factory {
public:
   static Config004 create(
      string _eaName
      , long _magicNumber
      , double _volume
      , double _tp      
      , int _longMaPeriod
      , int _longlongMaPeriod            
      , int _gridSize
      , ENUM_TIMEFRAMES _orderPeriod
   ) {
      Config004 config;
      config.eaName = _eaName;
      config.magicNumber = _magicNumber;
      config.volume = _volume;
      config.tp = _tp;
      config.longMaPeriod = _longMaPeriod;
      config.longlongMaPeriod = _longlongMaPeriod;      
      config.gridSize = _gridSize;
      config.orderPeriod = _orderPeriod;
      return config;
   }
};
