import 'package:flutter/material.dart';
import 'package:hotel_app/models/room.dart';

class RoomButton extends StatelessWidget {
  const RoomButton({
    super.key,
    required this.room,
    required this.occupied,
  });

  final Room room;
  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final statusColor = occupied
        ? const Color(0xFFD96B6B)
        : const Color(0xFF62B47A);
    final statusText = occupied ? 'Zajęty' : 'Wolny';

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Pokój ${room.roomNumber}'),
            content: Text(
              'Pojemność: ${room.capacity}\n'
              'Dodatkowe łóżko: ${room.extraBed ? 'Tak' : 'Nie'}\n'
              'Status: $statusText',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pokój ${room.roomNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              border: Border.all(color: statusColor, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'podgląd >',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
