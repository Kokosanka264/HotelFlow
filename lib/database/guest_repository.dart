import 'package:sqlite3/sqlite3.dart';

import 'database_helper.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/guest.dart';
import 'package:hotel_app/models/reservation.dart';
import 'package:hotel_app/models/room.dart';

class GuestRepository {
  GuestRepository({Database? database})
    : _database = database ?? DatabaseHelper.database;

  final Database _database;

  List<Guest> getGuestsBySearch(String query) {
    final search = '%$query%';
    final rows = _database.select('''
      SELECT id, guest_name, guest_surname, email, phone_number
      FROM guests
      WHERE guest_name LIKE ?
         OR guest_surname LIKE ?
         OR email LIKE ?
         OR phone_number LIKE ?
      ORDER BY guest_name COLLATE NOCASE, guest_surname COLLATE NOCASE, id
    ''', [search, search, search, search]);
    return rows
        .map(
          (row) => Guest(
            id: row['id'] as int,
            name: row['guest_name'] as String,
            surname: row['guest_surname'] as String,
            email: row['email'] as String?,
            phoneNumber: row['phone_number'] as String?,
          ),
        )
        .toList();
  }

  int? findGuestId({String? email, String? phoneNumber}) {
    return findGuest(email: email, phoneNumber: phoneNumber)?.id;
  }

  Guest? findGuest({String? email, String? phoneNumber}) {
    final normalizedEmail = _normalize(email);
    final normalizedPhoneNumber = _normalize(phoneNumber);
    if (normalizedEmail == null && normalizedPhoneNumber == null) {
      return null;
    }

    final conditions = <String>[];
    final arguments = <Object?>[];
    if (normalizedEmail != null) {
      conditions.add('email = ?');
      arguments.add(normalizedEmail);
    }
    if (normalizedPhoneNumber != null) {
      conditions.add('phone_number = ?');
      arguments.add(normalizedPhoneNumber);
    }

    final rows = _database.select(
      '''
      SELECT id, guest_name, guest_surname, email, phone_number
      FROM guests
      WHERE ${conditions.join(' OR ')}
      LIMIT 2
      ''',
      arguments,
    );

    if (rows.length > 1) {
      throw ArgumentError(
        'Multiple guest records match the supplied email or phone number.',
      );
    }
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    return Guest(
      id: row['id'] as int,
      name: row['guest_name'] as String,
      surname: row['guest_surname'] as String,
      email: row['email'] as String?,
      phoneNumber: row['phone_number'] as String?,
    );
  }

  int addGuest(
    String name,
    String surname,
    String? email,
    String? phoneNumber,
  ) {
    _database.execute(
      '''
      INSERT INTO guests (guest_name, guest_surname, email, phone_number)
      VALUES (?, ?, ?, ?)
      ''',
      [name.trim(), surname.trim(), _normalize(email), _normalize(phoneNumber)],
    );
    return _database.select('SELECT last_insert_rowid() AS id').first['id']
        as int;
  }

  bool updateGuest({
    required int guestId,
    required String name,
    required String surname,
    String? email,
    String? phoneNumber,
  }) {
    final normalizedName = name.trim();
    final normalizedSurname = surname.trim();
    if (normalizedName.isEmpty || normalizedSurname.isEmpty) {
      throw ArgumentError('Guest name and surname cannot be empty.');
    }

    _database.execute(
      '''
      UPDATE guests
      SET guest_name = ?, guest_surname = ?, email = ?, phone_number = ?
      WHERE id = ?
      ''',
      [
        normalizedName,
        normalizedSurname,
        _normalize(email),
        _normalize(phoneNumber),
        guestId,
      ],
    );
    return (_database.select('SELECT changes() AS count').first['count'] as int) >
        0;
  }

  bool removeGuestFromDb(int guestId) {
    _database.execute('DELETE FROM guests WHERE id = ?', [guestId]);
    return (_database.select('SELECT changes() AS count').first['count'] as int) >
        0;
  }

  List<Reservation> getReservationsByGuestId(int guestId) {
    final rows = _database.select(
      '''
      SELECT reservations.*, guests.guest_name, guests.guest_surname,
             guests.email, guests.phone_number
      FROM reservations
      JOIN guests ON guests.id = reservations.guest_id
      WHERE reservations.guest_id = ?
      ORDER BY reservations.check_in_date DESC, reservations.id DESC
      ''',
      [guestId],
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

  List<Room> _getReservedRooms(int reservationId) {
    final rows = _database.select(
      '''
      SELECT rooms.*
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
    final rows = _database.select(
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

  Map<int, bool> _getExtraBeds(int reservationId) {
    final rows = _database.select(
      '''
      SELECT room_id, extraBed
      FROM reservation_rooms
      WHERE reservation_id = ?
      ''',
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

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
