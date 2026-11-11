import 'package:flutter/material.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/room.dart';

class RoomConfigurationSection extends StatelessWidget {
  const RoomConfigurationSection({
    super.key,
    required this.rooms,
    required this.selectedConfigurations,
    required this.onConfigurationChanged,
    required this.selectedExtraBeds,
    required this.onExtraBedChanged,
    required this.numberOfGuests,
  });

  final List<Room> rooms;
  final Map<int, BedConfigurations> selectedConfigurations;
  final void Function(Room room, BedConfigurations? configuration)
  onConfigurationChanged;
  final Map<int, bool> selectedExtraBeds;
  final void Function(Room room, bool extraBed) onExtraBedChanged;
  final int numberOfGuests;

  String _configurationLabel(BedConfigurations configuration) {
    return switch (configuration) {
      BedConfigurations.single => 'Pojedyńcze łóżko',
      BedConfigurations.twin => 'Dwa oddzielne łóżka',
      BedConfigurations.doubleBed => 'Podwójne łóżko',
      BedConfigurations.fourSingle => 'Cztery pojedyńcze łóżka',
      BedConfigurations.doubleAndTwoSingle => 'Podwójne łóżko i dwa pojedyńcze',
    };
  }

  int _selectedSpots() {
    return rooms.fold(0, (total, room) {
      final configurationSpots =
          selectedConfigurations[room.id]?.spots ?? 0;
      final extraBedSpots = selectedExtraBeds[room.id] == true ? 1 : 0;
      return total + configurationSpots + extraBedSpots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Room Configuration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final room in rooms) ...[
          Text('Room ${room.roomNumber}'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BedConfigurations>(
                  isExpanded: true,
                  initialValue: selectedConfigurations[room.id],
                  decoration: const InputDecoration(
                    labelText: 'Bed configuration',
                  ),
                  items: room
                      .getPossibleBedConfigurations()
                      .map(
                        (configuration) => DropdownMenuItem(
                          value: configuration,
                          child: Text(_configurationLabel(configuration)),
                        ),
                      )
                      .toList(),
                  onChanged: (configuration) {
                    onConfigurationChanged(room, configuration);
                  },
                  validator: (configuration) => configuration == null
                      ? 'Select a configuration.'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Dodatkowe łóżko'),
              Switch(
                value: selectedExtraBeds[room.id] ?? false,
                onChanged: room.extraBed
                    ? (value) => onExtraBedChanged(room, value)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '${_selectedSpots()} / $numberOfGuests',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
