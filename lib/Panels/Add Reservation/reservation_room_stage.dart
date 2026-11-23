import 'package:flutter/material.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/room.dart';
import 'package:hotel_app/widgets/room_configuration_section.dart';

class ReservationRoomStage extends StatelessWidget {
  const ReservationRoomStage({
    super.key,
    required this.rooms,
    required this.selectedConfigurations,
    required this.selectedExtraBeds,
    required this.numberOfGuests,
    required this.onConfigurationChanged,
    required this.onExtraBedChanged,
  });

  final List<Room> rooms;
  final Map<int, BedConfigurations> selectedConfigurations;
  final Map<int, bool> selectedExtraBeds;
  final int numberOfGuests;
  final void Function(Room room, BedConfigurations? configuration)
  onConfigurationChanged;
  final void Function(Room room, bool extraBed) onExtraBedChanged;

  @override
  Widget build(BuildContext context) {
    return RoomConfigurationSection(
      rooms: rooms,
      selectedConfigurations: selectedConfigurations,
      selectedExtraBeds: selectedExtraBeds,
      numberOfGuests: numberOfGuests,
      onConfigurationChanged: onConfigurationChanged,
      onExtraBedChanged: onExtraBedChanged,
    );
  }
}
