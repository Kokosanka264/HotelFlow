import 'package:flutter/material.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/database/room_repository.dart';
import 'package:hotel_app/models/reservation.dart';
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
	State<AvaliableRoomsView> createState() =>
			_AvaliableRoomsViewState();
 
  
}

class _AvaliableRoomsViewState
		extends State<AvaliableRoomsView> {
	RoomRepository roomRepository = RoomRepository();
  List<Room> avaliableRooms = [];
  @override
void didUpdateWidget(
  covariant AvaliableRoomsView oldWidget,
) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.checkIn != widget.checkIn ||
      oldWidget.checkOut != widget.checkOut) {
    avaliableRooms = roomRepository.getAvaliableRooms(
      widget.checkIn,
      widget.checkOut,
    );
  }
}
  @override
  void initState() {
    
    super.initState();
   
    avaliableRooms = roomRepository.getAvaliableRooms(widget.checkIn, widget.checkOut);
  }

	@override
	Widget build(BuildContext context) {
		return ListView.builder(
					itemCount: avaliableRooms.length,
					itemBuilder: (context, index) {
						final avaliableRoom = avaliableRooms[index];
						return ListTile(
							title: Text(avaliableRoom.toString()),
							onTap: () => widget.onRoomPressed(avaliableRoom),
						);
					},
				);
			}
	}
