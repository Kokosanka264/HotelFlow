enum BedConfigurations {
  single(1),
  twin(2),
  doubleBed(2),
  fourSingle(4),
  doubleAndTwoSingle(4);
  final int spots;
  const BedConfigurations(this.spots);
}