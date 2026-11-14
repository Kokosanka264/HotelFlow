import 'package:hotel_app/models/bed_configuration.dart';

import 'calendar_date.dart';
import 'database_helper.dart';

import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/database/reservation_rooms_repository.dart';
import 'package:hotel_app/models/reservation.dart';
import 'package:hotel_app/models/room.dart';

class ReservationRepository {
  int? _nextReservationTotalGrosze;

  int seedFakeReservations({int count = 100}) {
    if (count <= 0) {
      throw ArgumentError('Fake reservation count must be positive.');
    }

    final database = DatabaseHelper.database;
    final existingSeed =
        database.select('''
      SELECT COUNT(*) AS count
      FROM guests
      WHERE guest_name LIKE 'Test Guest %'
        AND guest_surname LIKE 'Reservation %'
      ''').first['count']
            as int;
    if (existingSeed > 0) {
      return 0;
    }

    final rooms = database.select('SELECT id, capacity FROM rooms ORDER BY id');
    if (rooms.isEmpty) {
      throw StateError('Cannot seed reservations without rooms.');
    }

    final today = DateTime.now();
    final baseDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 100));
    var created = 0;
    var candidate = 0;

    database.execute('BEGIN TRANSACTION');
    var committed = false;
    try {
      while (created < count && candidate < count * rooms.length * 2) {
        final checkIn = baseDate.add(Duration(days: candidate * 3));
        final checkOut = checkIn.add(const Duration(days: 2));
        final checkInText = calendarDateText(checkIn);
        final checkOutText = calendarDateText(checkOut);
        Map<String, Object?>? selectedRoom;

        for (final room in rooms) {
          final roomId = room['id'] as int;
          final conflicts = database.select(
            '''
            SELECT 1
            FROM reservation_rooms AS rr
            JOIN reservations AS r ON r.id = rr.reservation_id
            WHERE rr.room_id = ?
              AND r.check_in_date < ?
              AND r.check_out_date > ?
            LIMIT 1
            ''',
            [roomId, checkOutText, checkInText],
          );
          if (conflicts.isEmpty) {
            selectedRoom = {'id': roomId, 'capacity': room['capacity'] as int};
            break;
          }
        }

        candidate++;
        if (selectedRoom == null) {
          continue;
        }

        final guestNumber = created + 1;
        database.execute(
          '''
          INSERT INTO guests (
            guest_name, guest_surname, email, phone_number
          ) VALUES (?, ?, ?, ?)
          ''',
          [
            'Test Guest $guestNumber',
            'Reservation $guestNumber',
            'test.guest$guestNumber@example.com',
            '+48000000${guestNumber.toString().padLeft(3, '0')}',
          ],
        );
        final guestId =
            database.select('SELECT last_insert_rowid() AS id').first['id']
                as int;
        final roomId = selectedRoom['id'] as int;
        final capacity = selectedRoom['capacity'] as int;
        final configuration = capacity >= 4 ? 'fourSingle' : 'twin';

        database.execute(
          '''
          INSERT INTO reservations (
            guest_id, guest_count, check_in_date, check_out_date, total_grosze
          ) VALUES (?, ?, ?, ?, ?)
          ''',
          [
            guestId,
            capacity >= 4 ? 4 : 2,
            checkInText,
            checkOutText,
            30000 + (created * 1000),
          ],
        );
        final reservationId =
            database.select('SELECT last_insert_rowid() AS id').first['id']
                as int;
        database.execute(
          '''
          INSERT INTO reservation_rooms (
            reservation_id, room_id, bed_configuration, extraBed
          ) VALUES (?, ?, ?, 0)
          ''',
          [reservationId, roomId, configuration],
        );
        created++;
      }

      if (created != count) {
        throw StateError(
          'Unable to create $count non-overlapping reservations.',
        );
      }
      database.execute('COMMIT');
      committed = true;
      DatabaseHelper.rebuildSearchIndexes();
      return created;
    } finally {
      if (!committed) {
        database.execute('ROLLBACK');
      }
    }
  }

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
    final normalizedCheckIn = calendarDate(checkInDate);
    final normalizedCheckOut = calendarDate(checkOutDate);
    final totalCapacity = reservedRooms.entries.fold(
      0,
      (total, entry) =>
          total + entry.value.spots + (extraBeds[entry.key] == true ? 1 : 0),
    );
    if (guestName.trim().isEmpty ||
        guestSurname.trim().isEmpty ||
        guestCount <= 0 ||
        !normalizedCheckOut.isAfter(normalizedCheckIn) ||
        reservedRooms.isEmpty ||
        guestCount > totalCapacity ||
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
          guestRepository.addGuest(
            guestName,
            guestSurname,
            email,
            phoneNumber,
            rebuildIndexes: false,
          );

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
          calendarDateText(normalizedCheckIn),
          calendarDateText(normalizedCheckOut),
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
      DatabaseHelper.rebuildSearchIndexes();
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
    DatabaseHelper.rebuildSearchIndexes();
    return changes > 0;
  }

  int removeReservationsOlderThanTwoMonths() {
    final database = DatabaseHelper.database;
    database.execute(
      '''
      DELETE FROM reservations
      WHERE DATE(check_out_date) < DATE(?, '-2 months')
    ''',
      [localTodayText()],
    );
    final removed =
        database.select('SELECT changes() AS count').first['count'] as int;
    if (removed > 0) {
      DatabaseHelper.rebuildSearchIndexes();
    }
    return removed;
  }

  List<Reservation> getReservationsForDate(DateTime date) {
    final String formattedDate = calendarDateText(date);
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

  List<Reservation> getPastReservations([String query = '']) {
    final ftsQuery = _ftsQuery(query);
    final searchClause = ftsQuery == null
        ? ''
        : 'AND reservation_search MATCH ?';
    final parameters = ftsQuery == null
        ? <Object?>[localTodayText()]
        : <Object?>[localTodayText(), ftsQuery];
    final rows = DatabaseHelper.database.select('''
      SELECT reservations.*, guests.guest_name, guests.guest_surname,
             guests.email, guests.phone_number
      FROM reservations
      JOIN guests ON guests.id = reservations.guest_id
      JOIN reservation_search ON reservation_search.reservation_id =
        reservations.id
      WHERE DATE(reservations.check_out_date) < DATE(?)
        $searchClause
      ORDER BY reservations.check_out_date DESC, reservations.id ASC
      ''', parameters);
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
    final result = DatabaseHelper.database.select(
      '''
      SELECT COUNT(*) AS total
      FROM reservations
      WHERE check_out_date >= DATE(?);
    ''',
      [localTodayText()],
    );
    return result.first['total'] as int;
  }

  List<Reservation> getReservationsPage(
    int page,
    int pageSize, [
    String query = '',
  ]) {
    final offset = page * pageSize;
    final ftsQuery = _ftsQuery(query);
    final searchClause = ftsQuery == null
        ? ''
        : 'AND reservation_search MATCH ?';
    final parameters = ftsQuery == null
        ? <Object?>[localTodayText(), pageSize, offset]
        : <Object?>[localTodayText(), ftsQuery, pageSize, offset];
    final rows = DatabaseHelper.database.select('''
      SELECT reservations.*, guests.guest_name, guests.guest_surname,
             guests.email, guests.phone_number
      FROM reservations
      JOIN guests ON guests.id = reservations.guest_id
      JOIN reservation_search ON reservation_search.reservation_id =
        reservations.id
      WHERE Date(reservations.check_out_date) >= Date(?)
        $searchClause
      ORDER BY reservations.check_in_date ASC, reservations.id ASC
      LIMIT ? OFFSET ?
      ''', parameters);
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

  String? _ftsQuery(String query) {
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .map((term) => term.replaceAll('"', ''))
        .where((term) => term.isNotEmpty)
        .map((term) => '"$term"*')
        .toList();
    return terms.isEmpty ? null : terms.join(' OR ');
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
