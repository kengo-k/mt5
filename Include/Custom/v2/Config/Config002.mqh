struct Config002 {
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
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
};

class Config002Factory {
public:
   static Config002 create(
      string _eaName
      , long _magicNumber
      , double _sl
      , double _tp
      , double _volume
      , int _longMaPeriod
      , int _longlongMaPeriod
   ) {
      Config002 config;
      config.eaName = _eaName;
      config.magicNumber = _magicNumber;
      config.sl = _sl;
      config.tp = _tp;
      config.volume = _volume;
      config.longMaPeriod = _longMaPeriod;
      config.longlongMaPeriod = _longlongMaPeriod;
      return config;
   }
};
