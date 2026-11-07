import 'package:flutter/material.dart';
import 'package:hotel_app/database/room_repository.dart';
import 'package:hotel_app/models/room.dart';
import 'package:hotel_app/widgets/room_button.dart';
class RoomsPanel extends StatelessWidget {
   RoomsPanel({super.key});
  final RoomRepository roomRepository = RoomRepository();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokoje'),
      ),
      body: Center(
        child: Column(children: [
          Expanded(
            child: ListView.builder(
              itemCount: loadRooms().length,
              itemBuilder: (context, index) {
                final room = loadRooms()[index];
               return ListTile(
               title: RoomButton(room: room),
                );
                
              },
            ),
          ),
        ],)
      ),
    );
  }
  List<Room> loadRooms(){
   return roomRepository.getAllRooms();
  }
}