import 'package:sqlite3/sqlite3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static Database? _database;

  static Database get database {
    if (_database == null) {
      throw StateError(
        'Database has not been initialized. Call createTables() first.',
      );
    }

    return _database!;
  }

  static Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'hotel.db');
    _database = sqlite3.open(dbPath);
    _database!.execute('PRAGMA foreign_keys = ON;');
    print('Database initialized at: $dbPath');
  }

  static void closeDatabase() {
    _database?.close();
    _database = null;
  }

  static void createTables() {
    database.execute('''
      CREATE TABLE IF NOT EXISTS rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_number TEXT NOT NULL UNIQUE,
        capacity INTEGER NOT NULL,
        extra_bed INTEGER NOT NULL DEFAULT 0
        CHECK(extra_bed IN (0, 1))
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        guest_name TEXT NOT NULL,
        guest_surname TEXT NOT NULL,
        email TEXT,
        phone_number TEXT,
        guest_count INTEGER NOT NULL
        CHECK(guest_count > 0),
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        FOREIGN KEY (room_id) REFERENCES rooms (id)
          ON DELETE RESTRICT
        CHECK(CHECK_IN_DATE < CHECK_OUT_DATE)
      )
    ''');
    database.execute('''
  CREATE INDEX IF NOT EXISTS idx_reservation_availability
  ON reservations(room_id, check_in_date, check_out_date);
''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_reservations_room_DATES ON reservations (room_id, check_in_date, check_out_date)
    ''');
    final tables = database.select(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    for (final table in tables) {
      print(table['name']);
    }
  }

  static void seedRooms() {
    for (int i = 1; i <= 24; i++) {
      bool isQuadruple = i == 12 || i == 24;

      database.execute(
        '''
      INSERT OR IGNORE INTO rooms
      (room_number, capacity, extra_bed)
      VALUES (?, ?, ?)
    ''',
        [i.toString(), isQuadruple ? 4 : 2, isQuadruple ? 0 : 1],
      );
    }
  }

  static void seedReservations() {
    final db = database;

    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);

    // 21 testowych rezerwacji
    final roomNumbers = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      21,
      24,
      2,
    ];

    final guestNames = [
      'Anna',
      'Jan',
      'Maria',
      'Piotr',
      'Katarzyna',
      'Adam',
      'Ewa',
      'Tomasz',
      'Julia',
      'Michał',
      'Zofia',
      'Paweł',
      'Natalia',
      'Jakub',
      'Oliwia',
      'Mateusz',
      'Alicja',
      'Kamil',
      'Weronika',
      'Filip',
      'Magdalena',
    ];

    final guestSurnames = [
      'Kowalska',
      'Nowak',
      'Wiśniewska',
      'Wójcik',
      'Kamińska',
      'Lewandowski',
      'Zielińska',
      'Szymański',
      'Woźniak',
      'Dąbrowski',
      'Kozłowska',
      'Jankowski',
      'Mazur',
      'Krawczyk',
      'Piotrowska',
      'Grabowski',
      'Pawlak',
      'Michalski',
      'Król',
      'Wieczorek',
      'Zając',
    ];

    int inserted = 0;

    for (int i = 0; i < 21; i++) {
      final roomNumber = roomNumbers[i].toString();

      // Pobierz rzeczywisty ID pokoju z bazy
      final roomRows = db.select(
        'SELECT id, capacity FROM rooms WHERE room_number = ?',
        [roomNumber],
      );

      if (roomRows.isEmpty) {
        continue;
      }

      final roomId = roomRows.first['id'] as int;
      final capacity = roomRows.first['capacity'] as int;

      // 1-2 osoby, a w pokojach 4-osobowych do 4
      final guestCount = capacity == 4 ? 3 + (i % 2) : 1 + (i % 2);

      // Każda kolejna rezerwacja zaczyna się później
      final checkIn = startDate.add(Duration(days: 1 + i * 2));
      final checkOut = checkIn.add(Duration(days: 2 + (i % 3)));

      final checkInString = checkIn.toIso8601String().split('T')[0];
      final checkOutString = checkOut.toIso8601String().split('T')[0];

      // Unikalny znacznik testowej rezerwacji
      final email = 'hotelflow-seed-$i@example.invalid';

      // Nie dodawaj tego samego testowego rekordu ponownie
      final alreadySeeded = db.select(
        'SELECT id FROM reservations WHERE email = ? LIMIT 1',
        [email],
      );

      if (alreadySeeded.isNotEmpty) {
        continue;
      }

      // Sprawdź, czy pokój jest wolny w wybranym terminie
      final conflicts = db.select(
        '''
      SELECT id FROM reservations
      WHERE room_id = ?
        AND check_in_date < ?
        AND check_out_date > ?
      LIMIT 1
      ''',
        [roomId, checkOutString, checkInString],
      );

      if (conflicts.isNotEmpty) {
        print('Pominięto rezerwację: pokój $roomNumber jest zajęty.');
        continue;
      }

      db.execute(
        '''
      INSERT INTO reservations (
        room_id,
        guest_name,
        guest_surname,
        email,
        phone_number,
        guest_count,
        check_in_date,
        check_out_date
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          roomId,
          guestNames[i],
          guestSurnames[i],
          email,
          null,
          guestCount,
          checkInString,
          checkOutString,
        ],
      );

      inserted++;
    }

    print('Dodano $inserted nowych testowych rezerwacji.');
  }
}
