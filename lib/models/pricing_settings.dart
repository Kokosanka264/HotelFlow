class PricingSettings {
  const PricingSettings({
    required this.capacityTwoGrosze,
    required this.capacityFourGrosze,
    required this.extraBedGrosze,
  });

  final int capacityTwoGrosze;
  final int capacityFourGrosze;
  final int extraBedGrosze;

  int roomRateForCapacity(int capacity) {
    return capacity == 4 ? capacityFourGrosze : capacityTwoGrosze;
  }
}
