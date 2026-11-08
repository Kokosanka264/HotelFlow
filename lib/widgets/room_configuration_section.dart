import 'package:flutter/material.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/room.dart';

class RoomConfigurationSection extends StatelessWidget {
  const RoomConfigurationSection({
    super.key,
    required this.rooms,
    required this.selectedConfigurations,
    required this.onConfigurationChanged,
  });

  final List<Room> rooms;
  final Map<int, BedConfigurations> selectedConfigurations;
  final void Function(Room room, BedConfigurations? configuration)
  onConfigurationChanged;

  String _configurationLabel(BedConfigurations configuration) {
    return switch (configuration) {
      BedConfigurations.single => 'Single bed',
      BedConfigurations.twin => 'Twin beds',
      BedConfigurations.doubleBed => 'Double bed',
      BedConfigurations.extraBed => 'Extra bed',
      BedConfigurations.fourSingle => 'Four single beds',
      BedConfigurations.doubleAndTwoSingle => 'Double bed and two single beds',
    };
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
          DropdownButtonFormField<BedConfigurations>(
            initialValue: selectedConfigurations[room.id],
            decoration: const InputDecoration(labelText: 'Bed configuration'),
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
            validator: (configuration) =>
                configuration == null ? 'Select a configuration.' : null,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
