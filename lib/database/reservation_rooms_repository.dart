import 'package:hotel_app/models/bed_configuration.dart';

import 'database_helper.dart';

import 'package:hotel_app/models/reservation.dart';
import 'package:hotel_app/models/room.dart';
class ReservationRoomsRepository {
  void addRoomReservation(int reservationId,Room room, BedConfigurations configuration){
    DatabaseHelper.database.execute(
      '''
      INSERT INTO reservation_rooms (
         reservation_id, room_id, bed_configuration
      ) VALUES ( ?, ?, ?)
    ''',
      [
        reservationId,
        room.getId(),
        configuration.name
      ],
    );

  }
}