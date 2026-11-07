import 'database_helper.dart';
import 'package:flutter/material.dart';
import 'package:hotel_app/models/room.dart';
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
  List<Room> getAllRooms(){
    final rows = DatabaseHelper.database.select('SELECT * FROM rooms');
    return rows.map((row) => Room(
      id: row['id'] as int,
      roomNumber: row['room_number'] as String,
      capacity: row['capacity'] as int,
      extraBed: (row['extra_bed'] as int) == 1,
    )).toList();
  }
  List<Room> getAvaliableRooms(DateTime checkIn, DateTime checkOut){
     final checkInString = checkIn.toIso8601String().split('T')[0];
  final checkOutString = checkOut.toIso8601String().split('T')[0];

  final rows = DatabaseHelper.database.select(
    '''
    SELECT rooms.*
    FROM rooms
    WHERE NOT EXISTS (
      SELECT 1
      FROM reservations AS r
      WHERE r.room_id = rooms.id
        AND r.check_in_date < ?
        AND r.check_out_date > ?
    )
    ORDER BY rooms.id ASC
    ''',
    [checkOutString, checkInString],
  );
  return rows.map((row)=> Room(
    id: row['id'] as int,
      roomNumber: row['room_number'] as String,
      capacity: row['capacity'] as int,
      extraBed: (row['extra_bed'] as int) == 1,
  )
  ).toList();
  }

  
}