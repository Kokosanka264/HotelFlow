import 'package:flutter/material.dart';
import 'package:hotel_app/database/room_repository.dart';
import 'package:hotel_app/models/room.dart';
import 'package:hotel_app/widgets/room_button.dart';

class RoomsPanel extends StatelessWidget {
  RoomsPanel({super.key});
  final RoomRepository roomRepository = RoomRepository();

  @override
  Widget build(BuildContext context) {
    final rooms = loadRooms();
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final availableRoomIds = roomRepository
        .getAvaliableRooms(today, tomorrow)
        .map((room) => room.id)
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Pokoje')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return RoomButton(
              room: room,
              occupied: !availableRoomIds.contains(room.id),
            );
          },
        ),
      ),
    );
  }

  List<Room> loadRooms() {
    return roomRepository.getAllRooms();
  }
}