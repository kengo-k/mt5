interface IVolumeCalculator {
  double getGridVolume();
  double getHedgeVolume();
  void update();
};

// 常に定数のボリュームを返却するCalculator
class FixedVolumeCalculator : public IVolumeCalculator {
public:
  FixedVolumeCalculator(double _gridVolume, double _hedgeVolume):
    gridVolume(_gridVolume)
    , hedgeVolume(_hedgeVolume) {}

  double getGridVolume() {
    return this.gridVolume;
  }

  double getHedgeVolume() {
    return this.hedgeVolume;
  }

  void update() {}
private:
  double gridVolume;
  double hedgeVolume;
};

// 残高に応じてボリュームを増減させるCalculator
class IncreaseVolumeCalculator : public IVolumeCalculator {
public:

  IncreaseVolumeCalculator(
    double _baseMargin
    , double _baseVolume
    , double _threshold
    , double _increase
    , double _gridHedgeRatio):
      margin(0)
      , baseMargin(_baseMargin)
      , baseVolume(_baseVolume)
      , threshold(_threshold)
      , increase(_increase)
      , gridHedgeRatio(_gridHedgeRatio) {}

  double getGridVolume() {
    double diff = this.margin - baseMargin;
    if (diff < 0) {
      return this.baseVolume;
    }
    int q = (int) floor(diff / this.threshold);
    return this.baseVolume + (q * this.increase);
  }

  double getHedgeVolume() {
    return this.getGridVolume() * this.gridHedgeRatio;
  }

  void update() {
    this.margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
  }

  void setMargin(double _margin) {
    this.margin = _margin;
  }

private:
  double margin;
  double baseMargin;
  double baseVolume;
  double threshold;
  double increase;
  double gridHedgeRatio;
};
