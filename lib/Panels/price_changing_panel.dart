import 'package:flutter/material.dart';
import 'package:hotel_app/database/pricing_repository.dart';
import 'package:hotel_app/models/pricing_settings.dart';

class PriceChangingPanel extends StatefulWidget {
  const PriceChangingPanel({super.key, this.pricingRepository});

  final PricingRepository? pricingRepository;

  @override
  State<PriceChangingPanel> createState() => _PriceChangingPanelState();
}

class _PriceChangingPanelState extends State<PriceChangingPanel> {
  late final PricingRepository _pricingRepository =
      widget.pricingRepository ?? PricingRepository();
  late final TextEditingController _capacityTwoController;
  late final TextEditingController _capacityFourController;
  late final TextEditingController _extraBedController;

  @override
  void initState() {
    super.initState();
    final settings = _pricingRepository.getSettings();
    _capacityTwoController = TextEditingController(
      text: _plnText(settings.capacityTwoGrosze),
    );
    _capacityFourController = TextEditingController(
      text: _plnText(settings.capacityFourGrosze),
    );
    _extraBedController = TextEditingController(
      text: _plnText(settings.extraBedGrosze),
    );
  }

  @override
  void dispose() {
    _capacityTwoController.dispose();
    _capacityFourController.dispose();
    _extraBedController.dispose();
    super.dispose();
  }

  String _plnText(int grosze) => (grosze / 100).toStringAsFixed(2);

  int? _parseGrosze(String value) {
    final amount = double.tryParse(value.trim().replaceAll(',', '.'));
    if (amount == null || amount.isNaN || amount.isInfinite || amount < 0) {
      return null;
    }
    return (amount * 100).round();
  }

  void _savePricing() {
    final capacityTwo = _parseGrosze(_capacityTwoController.text);
    final capacityFour = _parseGrosze(_capacityFourController.text);
    final extraBed = _parseGrosze(_extraBedController.text);
    if (capacityTwo == null ||
        capacityTwo == 0 ||
        capacityFour == null ||
        capacityFour == 0 ||
        extraBed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź poprawne ceny w PLN.')),
      );
      return;
    }

    _pricingRepository.saveSettings(
      PricingSettings(
        capacityTwoGrosze: capacityTwo,
        capacityFourGrosze: capacityFour,
        extraBedGrosze: extraBed,
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cennik został zapisany.')));
  }

  Widget _priceField(String label, TextEditingController controller) {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'PLN / noc',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cennik pokoi',
            style: TextStyle(
              color: Color(0xFF3F3940),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _priceField('Pokój 2-osobowy', _capacityTwoController),
          const SizedBox(height: 16),
          _priceField('Pokój 4-osobowy', _capacityFourController),
          const SizedBox(height: 16),
          _priceField('Dodatkowe łóżko', _extraBedController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _savePricing,
            child: const Text('Zapisz cennik'),
          ),
        ],
      ),
    );
  }
}
