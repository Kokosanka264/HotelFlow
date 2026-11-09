import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/database/pricing_repository.dart';
import 'package:hotel_app/models/pricing_settings.dart';

void main() {
  test('default pricing uses the configured PLN rates', () {
    final settings = PricingRepository.defaults;

    expect(settings.capacityTwoGrosze, 30000);
    expect(settings.capacityFourGrosze, 50000);
    expect(settings.extraBedGrosze, 6000);
    expect(settings.roomRateForCapacity(2), 30000);
    expect(settings.roomRateForCapacity(4), 50000);
  });

  test('pricing rates are represented as integer grosze', () {
    const settings = PricingSettings(
      capacityTwoGrosze: 3050,
      capacityFourGrosze: 5075,
      extraBedGrosze: 625,
    );

    expect(settings.roomRateForCapacity(2), 3050);
    expect(settings.roomRateForCapacity(4), 5075);
    expect(settings.extraBedGrosze, 625);
  });
}
