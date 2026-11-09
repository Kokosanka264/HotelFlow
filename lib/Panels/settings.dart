import 'package:flutter/material.dart';
import 'package:hotel_app/database/pricing_repository.dart';
import 'package:hotel_app/Panels/price_changing_panel.dart';
import 'package:hotel_app/widgets/sidebar_button.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.onClose,
    this.pricingRepository,
  });

  final VoidCallback onClose;
  final PricingRepository? pricingRepository;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  int selectedSection = 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F2EE),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ustawienia',
                  style: TextStyle(
                    color: Color(0xFF3F3940),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 210,
                        child: Column(
                          children: [
                            SidebarButton(
                              text: 'Cennik',
                              icon: Icons.price_change_rounded,
                              isSelected: selectedSection == 0,
                              onPressed: () {
                                setState(() {
                                  selectedSection = 0;
                                });
                              },
                            ),
                            SidebarButton(
                              text: 'Historia rezerwacji',
                              icon: Icons.history_rounded,
                              isSelected: selectedSection == 1,
                              onPressed: () {
                                setState(() {
                                  selectedSection = 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(
                        color: Color(0xFFE8E0DF),
                        width: 32,
                      ),
                      Expanded(
                        child: selectedSection == 0
                            ? PriceChangingPanel(
                                pricingRepository: widget.pricingRepository,
                              )
                            : const Center(
                                child: Text(
                                  'Historia rezerwacji będzie dostępna wkrótce.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: widget.onClose,
              tooltip: 'Zamknij ustawienia',
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
