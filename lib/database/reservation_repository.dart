

import 'package:hotel_app/models/bed_configuration.dart';

import 'database_helper.dart';
import 'package:hotel_app/database/reservation_rooms_repository.dart';
import 'package:hotel_app/models/reservation.dart';
import 'package:hotel_app/models/room.dart';

class ReservationRepository {
  void addReservation({
    required Map<Room,BedConfigurations> reservedRooms,
    required String guestName,
    required String guestSurname,
    String? email,
    String? phoneNumber,
    required int guestCount,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    if (guestName.trim().isEmpty ||
        guestSurname.trim().isEmpty ||
        guestCount <= 0 ||
        checkInDate.isAfter(checkOutDate)) {
      throw ArgumentError('Invalid reservation data.');
    }

    DatabaseHelper.database.execute(
      '''
      INSERT INTO reservations (
         guest_name, guest_surname, email, phone_number, guest_count, check_in_date, check_out_date
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        guestName,
        guestSurname,
        email,
        phoneNumber,
        guestCount,
        checkInDate.toIso8601String().split('T')[0],
        checkOutDate.toIso8601String().split('T')[0],
      ],
    );
    final roomRepository = ReservationRoomsRepository();
    final reservationId = DatabaseHelper.database
    .select('SELECT last_insert_rowid() AS id')
    .first['id'] as int;

    for (final entry in reservedRooms.entries) {
      roomRepository.addRoomReservation(reservationId,entry.key, entry.value);
    }

  }

  List<Reservation> getReservationsForDate(DateTime date) {
    final String formattedDate = date.toIso8601String().split('T')[0];
    final rows = DatabaseHelper.database.select(
      '''
      SELECT * FROM reservations
      WHERE DATE(check_in_date) <= ? AND DATE(check_out_date) > ?
      ''',
      [formattedDate, formattedDate],
    );
    return rows.map((row) {
      final reservationId = row['id'] as int;
      return Reservation(
        id: reservationId,
        reservedRooms: _getReservedRooms(reservationId),
        guestName: row['guest_name'] as String,
        guestSurname: row['guest_surname'] as String,
        email: row['email'] as String?,
        phoneNumber: row['phone_number'] as String?,
        guestCount: row['guest_count'] as int,
        checkInDate: DateTime.parse(row['check_in_date'] as String),
        checkOutDate: DateTime.parse(row['check_out_date'] as String),
      );
    }).toList();
  }

  List<Reservation> getReservationsPage(int page, int pageSize) {
    final offset = page * pageSize;
    final rows = DatabaseHelper.database.select(
      '''
      SELECT * FROM reservations
      WHERE Date(check_out_date) >= Date('now')
      ORDER BY check_in_date ASC, id ASC
      LIMIT ? OFFSET ?
      ''',
      [pageSize, offset],
    );
    return rows.map((row) {
      final reservationId = row['id'] as int;
      return Reservation(
        id: reservationId,
        reservedRooms: _getReservedRooms(reservationId),
        guestName: row['guest_name'] as String,
        guestSurname: row['guest_surname'] as String,
        email: row['email'] as String?,
        phoneNumber: row['phone_number'] as String?,
        guestCount: row['guest_count'] as int,
        checkInDate: DateTime.parse(row['check_in_date'] as String),
        checkOutDate: DateTime.parse(row['check_out_date'] as String),
      );
    }).toList();
  }

  List<Room> _getReservedRooms(int reservationId) {
    final rows = DatabaseHelper.database.select(
      '''
      SELECT *
      FROM reservation_rooms
      JOIN rooms ON rooms.id = reservation_rooms.room_id
      WHERE reservation_rooms.reservation_id = ?
      ORDER BY rooms.id
      ''',
      [reservationId],
    );

    return rows
        .map(
          (row) => Room(
            id: row['id'] as int,
            roomNumber: row['room_number'] as String,
            capacity: row['capacity'] as int,
            extraBed: (row['extra_bed'] as int) == 1,
          ),
        )
        .toList();
  }
}
