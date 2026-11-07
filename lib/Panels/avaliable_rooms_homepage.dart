import 'package:flutter/material.dart';
import 'package:hotel_app/database/room_repository.dart';
import 'package:hotel_app/models/room.dart';

class AvaliableRoomsView extends StatefulWidget {
  const AvaliableRoomsView({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onRoomPressed,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final void Function(Room) onRoomPressed;

  @override
  State<AvaliableRoomsView> createState() => _AvaliableRoomsViewState();
}

class _AvaliableRoomsViewState extends State<AvaliableRoomsView> {
  final RoomRepository roomRepository = RoomRepository();
  List<Room> avaliableRooms = [];
  final List<Room> selectedRooms = [];

  @override
  void didUpdateWidget(covariant AvaliableRoomsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.checkIn != widget.checkIn ||
        oldWidget.checkOut != widget.checkOut) {
      avaliableRooms = roomRepository.getAvaliableRooms(
        widget.checkIn,
        widget.checkOut,
      );
      selectedRooms.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    avaliableRooms = roomRepository.getAvaliableRooms(
      widget.checkIn,
      widget.checkOut,
    );
  }

  void toggleRoomSelection(Room room) {
    setState(() {
      final selectedIndex = selectedRooms.indexWhere(
        (selectedRoom) => selectedRoom.id == room.id,
      );
      if (selectedIndex == -1) {
        selectedRooms.add(room);
      } else {
        selectedRooms.removeAt(selectedIndex);
      }
    });
    widget.onRoomPressed(room);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: avaliableRooms.length,
      itemBuilder: (context, index) {
        final avaliableRoom = avaliableRooms[index];
        final isSelected = selectedRooms.any(
          (selectedRoom) => selectedRoom.id == avaliableRoom.id,
        );

        return ListTile(
          title: Text(avaliableRoom.toString()),
          selected: isSelected,
          tileColor: isSelected
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          onTap: () => toggleRoomSelection(avaliableRoom),
        );
      },
    );
  }
}
