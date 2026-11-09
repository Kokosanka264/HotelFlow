import 'package:hotel_app/database/database_helper.dart';
import 'package:hotel_app/models/pricing_settings.dart';

class PricingRepository {
  static const defaults = PricingSettings(
    capacityTwoGrosze: 30000,
    capacityFourGrosze: 50000,
    extraBedGrosze: 6000,
  );

  PricingSettings getSettings() {
    try {
      final rows = DatabaseHelper.database.select(
        'SELECT capacity_two_grosze, capacity_four_grosze, extra_bed_grosze '
        'FROM pricing_settings WHERE id = 1',
      );
      if (rows.isEmpty) {
        return defaults;
      }

      return PricingSettings(
        capacityTwoGrosze: rows.first['capacity_two_grosze'] as int,
        capacityFourGrosze: rows.first['capacity_four_grosze'] as int,
        extraBedGrosze: rows.first['extra_bed_grosze'] as int,
      );
    } on StateError {
      return defaults;
    }
  }

  void saveSettings(PricingSettings settings) {
    _validate(settings);
    DatabaseHelper.database.execute(
      '''
      INSERT INTO pricing_settings (
        id, capacity_two_grosze, capacity_four_grosze, extra_bed_grosze
      ) VALUES (1, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        capacity_two_grosze = excluded.capacity_two_grosze,
        capacity_four_grosze = excluded.capacity_four_grosze,
        extra_bed_grosze = excluded.extra_bed_grosze
      ''',
      [
        settings.capacityTwoGrosze,
        settings.capacityFourGrosze,
        settings.extraBedGrosze,
      ],
    );
  }

  void _validate(PricingSettings settings) {
    if (settings.capacityTwoGrosze <= 0 ||
        settings.capacityFourGrosze <= 0 ||
        settings.extraBedGrosze < 0) {
      throw ArgumentError('Prices must be valid non-negative amounts.');
    }
  }
}
