import 'package:hotel_app/models/bed_configuration.dart';

import 'database_helper.dart';

import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/database/reservation_rooms_repository.dart';
import 'package:hotel_app/models/reservation.dart';
import 'package:hotel_app/models/room.dart';

class ReservationRepository {
  int? _nextReservationTotalGrosze;

  void setNextReservationTotalGrosze(int totalGrosze) {
    if (totalGrosze < 0) {
      throw ArgumentError('Reservation total cannot be negative.');
    }
    _nextReservationTotalGrosze = totalGrosze;
  }

  void addReservation({
    required Map<Room, BedConfigurations> reservedRooms,
    Map<Room, bool> extraBeds = const {},
    required String guestName,
    required String guestSurname,
    String? email,
    String? phoneNumber,
    int? guestId,
    required int guestCount,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    if (guestName.trim().isEmpty ||
        guestSurname.trim().isEmpty ||
        guestCount <= 0 ||
        !checkOutDate.isAfter(checkInDate) ||
        reservedRooms.isEmpty ||
        extraBeds.keys.any((room) => !reservedRooms.containsKey(room)) ||
        extraBeds.entries.any((entry) => entry.value && !entry.key.extraBed) ||
        reservedRooms.entries.any(
          (entry) =>
              !entry.key.getPossibleBedConfigurations().contains(entry.value),
        )) {
      throw ArgumentError('Invalid reservation data.');
    }

    final database = DatabaseHelper.database;
    database.execute('BEGIN TRANSACTION');
    var committed = false;
    try {
      final guestRepository = GuestRepository();
      final resolvedGuestId =
          guestId ??
          guestRepository.addGuest(guestName, guestSurname, email, phoneNumber);

      database.execute(
        '''
        INSERT INTO reservations (
          guest_id, guest_count,
          check_in_date, check_out_date, total_grosze
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        [
          resolvedGuestId,
          guestCount,
          checkInDate.toIso8601String().split('T')[0],
          checkOutDate.toIso8601String().split('T')[0],
          _nextReservationTotalGrosze ?? 0,
        ],
      );
      final reservationId =
          database.select('SELECT last_insert_rowid() AS id').first['id']
              as int;
      final roomRepository = ReservationRoomsRepository();

      for (final entry in reservedRooms.entries) {
        roomRepository.addRoomReservation(
          reservationId,
          entry.key,
          entry.value,
          extraBed: extraBeds[entry.key] ?? false,
        );
      }

      database.execute('COMMIT');
      committed = true;
    } finally {
      _nextReservationTotalGrosze = null;
      if (!committed) {
        database.execute('ROLLBACK');
      }
    }
  }

  bool removeReservationFromDb(Reservation reservation) {
    final database = DatabaseHelper.database;
    database.execute('DELETE FROM reservations WHERE id = ?', [reservation.id]);
    final changes =
        database.select('SELECT changes() AS count').first['count'] as int;
    return changes > 0;
  }

  List<Reservation> getReservationsForDate(DateTime date) {
    final String formattedDate = date.toIso8601String().split('T')[0];
    final rows = DatabaseHelper.database.select(
      '''
      SELECT reservations.*, guests.guest_name, guests.guest_surname,
             guests.email, guests.phone_number
      FROM reservations
      JOIN guests ON guests.id = reservations.guest_id
      WHERE DATE(check_in_date) <= ? AND DATE(check_out_date) >= ?
      ''',
      [formattedDate, formattedDate],
    );
    return rows.map((row) {
      final reservationId = row['id'] as int;
      return Reservation(
        id: reservationId,
        reservedRooms: _getReservedRooms(reservationId),
        bedConfigurations: _getBedConfigurations(reservationId),
        extraBeds: _getExtraBeds(reservationId),
        guestName: row['guest_name'] as String,
        guestSurname: row['guest_surname'] as String,
        email: row['email'] as String?,
        phoneNumber: row['phone_number'] as String?,
        guestCount: row['guest_count'] as int,
        checkInDate: DateTime.parse(row['check_in_date'] as String),
        checkOutDate: DateTime.parse(row['check_out_date'] as String),
        totalGrosze: row['total_grosze'] as int,
      );
    }).toList();
  }

  int countReservations() {
    final result = DatabaseHelper.database.select('''
      SELECT COUNT(*) AS total
      FROM reservations
      WHERE check_out_date >= DATE('now');
    ''');
    return result.first['total'] as int;
  }

  List<Reservation> getReservationsPage(
    int page,
    int pageSize, [
    String query = '',
  ]) {
    final offset = page * pageSize;
    final search = '%${query.trim()}%';
    final rows = DatabaseHelper.database.select(
      '''
      SELECT reservations.*, guests.guest_name, guests.guest_surname,
             guests.email, guests.phone_number
      FROM reservations
      JOIN guests ON guests.id = reservations.guest_id
      WHERE Date(reservations.check_out_date) >= Date('now')
        AND (
          ? = ''
          OR guests.guest_name LIKE ?
          OR guests.guest_surname LIKE ?
          OR guests.email LIKE ?
          OR guests.phone_number LIKE ?
          OR CAST(reservations.id AS TEXT) LIKE ?
          OR CAST(reservations.guest_count AS TEXT) LIKE ?
          OR reservations.check_in_date LIKE ?
          OR reservations.check_out_date LIKE ?
        )
      ORDER BY reservations.check_in_date ASC, reservations.id ASC
      LIMIT ? OFFSET ?
      ''',
      [
        query.trim(),
        search,
        search,
        search,
        search,
        search,
        search,
        search,
        search,
        pageSize,
        offset,
      ],
    );
    return rows.map((row) {
      final reservationId = row['id'] as int;
      return Reservation(
        id: reservationId,
        reservedRooms: _getReservedRooms(reservationId),
        bedConfigurations: _getBedConfigurations(reservationId),
        extraBeds: _getExtraBeds(reservationId),
        guestName: row['guest_name'] as String,
        guestSurname: row['guest_surname'] as String,
        email: row['email'] as String?,
        phoneNumber: row['phone_number'] as String?,
        guestCount: row['guest_count'] as int,
        checkInDate: DateTime.parse(row['check_in_date'] as String),
        checkOutDate: DateTime.parse(row['check_out_date'] as String),
        totalGrosze: row['total_grosze'] as int,
      );
    }).toList();
  }

  Map<int, bool> _getExtraBeds(int reservationId) {
    final rows = DatabaseHelper.database.select(
      'SELECT room_id, extraBed FROM reservation_rooms WHERE reservation_id = ?',
      [reservationId],
    );
    return {
      for (final row in rows)
        row['room_id'] as int: _parseExtraBed(row['extraBed']),
    };
  }

  bool _parseExtraBed(Object? value) {
    if (value == 1 || value == '1' || value == 'true') {
      return true;
    }
    if (value == 0 || value == '0' || value == 'false') {
      return false;
    }
    throw FormatException('Invalid extra-bed value: $value');
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

  Map<int, BedConfigurations> _getBedConfigurations(int reservationId) {
    final rows = DatabaseHelper.database.select(
      '''
      SELECT room_id, bed_configuration
      FROM reservation_rooms
      WHERE reservation_id = ?
      ''',
      [reservationId],
    );

    return {
      for (final row in rows)
        row['room_id'] as int: BedConfigurations.values.byName(
          row['bed_configuration'] as String,
        ),
    };
  }
}
