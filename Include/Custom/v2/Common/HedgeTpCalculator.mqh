#include <Custom/v2/Common/VolumeCalculator.mqh>

interface IHedgeTpCalculator {
   int getHedgeTp();
   string toString();
};

class FixedHedgeTpCalculator  : public IHedgeTpCalculator {
public:
   FixedHedgeTpCalculator(int _hedgeTp)
      : hedgeTp(_hedgeTp) {}

   int getHedgeTp() {
      return this.hedgeTp;
   }

   string toString() {
      return StringFormat("%d", this.hedgeTp);
   }
private:
   int hedgeTp;
};

extern IVolumeCalculator *__volumeCalculator;
class IncreaseHedgeTpCalculator  : public IHedgeTpCalculator {
public:
   IncreaseHedgeTpCalculator(int _hedgeTp, double _baseVolume)
      : hedgeTp(_hedgeTp)
        , baseVolume(_baseVolume) {}

   int getHedgeTp() {
      return (int) NormalizeDouble(this.hedgeTp * (__volumeCalculator.getHedgeVolume() / this.baseVolume), 0);
   }

   string toString() {
      return StringFormat("%d, %f", this.hedgeTp, this.baseVolume);
   }

private:
   int hedgeTp;
   double baseVolume;
};
