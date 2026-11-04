import 'database_helper.dart';
class RoomRepository {
  void addRoom( { required String roomNumber, required int capacity, required bool extrabed}){
      if(roomNumber.trim().isEmpty || capacity <= 0){
        throw ArgumentError('Invalid data error.');
      }
      DatabaseHelper.database.execute('''
        INSERT INTO rooms (room_number, capacity, extra_bed)
        VALUES (?, ?, ?)
      ''', [roomNumber, capacity, extrabed ? 1 : 0]);
  }

  
}