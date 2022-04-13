struct Config001 {
   // 動作させているEAの名前
   string eaName;
   // どのEAによるポジションかを識別するための番号
   long magicNumber;
   // ストップ幅(pips)
   double sl;
   // 利益確定幅
   double tp;
   // 取引量
   double volume;
   // 短期MA期間
   int shortMaPeriod;
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
   // MACD期間
   int macdPeriod[3];
};

class ConfigFactory {
public:
   Config001 create(
      string _eaName
      , long _magicNumber
      , double _sl
      , double _tp
      , double _volume
      , int _shortMaPeriod
      , int _longMaPeriod
      , int _longlongMaPeriod
      , int _macdPeriod1
      , int _macdPeriod2
      , int _macdPeriod3
   ) {
      Config001 config;
      config.eaName = _eaName;
      config.magicNumber = _magicNumber;
      config.sl = _sl;
      config.tp = _tp;
      config.volume = _volume;
      config.shortMaPeriod = _shortMaPeriod;
      config.longMaPeriod = _longMaPeriod;
      config.longlongMaPeriod = _longlongMaPeriod;
      config.macdPeriod[0] = _macdPeriod1;
      config.macdPeriod[1] = _macdPeriod2;
      config.macdPeriod[2] = _macdPeriod3;
      return config;
   }
};
