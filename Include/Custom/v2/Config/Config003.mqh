struct Config003 {
   // 動作させているEAの名前
   string eaName;
   // どのEAによるポジションかを識別するための番号
   long magicNumber;
   // 初期ストップ(pips)
   double initialSL;
   // ストップ更新目標(pips)
   double nextSL;
   // トレール幅(pips)
   double trail;
   // 取引量
   double volume;
   // 長期MA期間
   int longMaPeriod;
   // 超長期MA期間
   int longlongMaPeriod;
};

class Config003Factory {
public:
   static Config003 create(
      string _eaName
      , long _magicNumber
      , double _initialSL
      , double _nextSL
      , double _trail
      , double _volume
      , int _longMaPeriod
      , int _longlongMaPeriod
   ) {
      Config003 config;
      config.eaName = _eaName;
      config.magicNumber = _magicNumber;
      config.initialSL = _initialSL;
      config.nextSL = _nextSL;
      config.trail = _trail;
      config.volume = _volume;
      config.longMaPeriod = _longMaPeriod;
      config.longlongMaPeriod = _longlongMaPeriod;
      return config;
   }
};
