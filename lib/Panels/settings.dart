import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F2EE),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Center(
            child: Text(
              'Ustawienia',
              style: TextStyle(
                color: Color(0xFF3F3940),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: onClose,
              tooltip: 'Zamknij ustawienia',
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
