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
      CREATE TABLE IF NOT EXISTS guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guest_name TEXT NOT NULL,
        guest_surname TEXT NOT NULL,
        email TEXT,
        phone_number TEXT

        
       
      )
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guest_id INTEGER NOT NULL,
        guest_count INTEGER NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        CHECK(guest_count > 0),
        CHECK(CHECK_IN_DATE < CHECK_OUT_DATE),

        FOREIGN KEY (guest_id)
    REFERENCES guests(id)
    ON DELETE RESTRICT
      )
    ''');

    database.execute('''
    CREATE TABLE IF NOT EXISTS reservation_rooms (
    reservation_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    bed_configuration TEXT NOT NULL,
    extraBed INTEGER NOT NULL DEFAULT 0 CHECK(extraBed IN (0, 1)),
    PRIMARY KEY (reservation_id, room_id),

    FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE CASCADE,

    FOREIGN KEY (room_id)
        REFERENCES rooms(id)
        ON DELETE RESTRICT
      )
     ''');

    database.execute('''
  CREATE INDEX IF NOT EXISTS idx_reservations_dates
  ON reservations(check_in_date, check_out_date);
''');

    database.execute('''
  CREATE INDEX IF NOT EXISTS idx_reservation_rooms_room
  ON reservation_rooms(room_id, reservation_id);
''');

    database.execute('''
 CREATE INDEX IF NOT EXISTS idx_guests_email
ON guests(email);
''');
    database.execute('''
  CREATE INDEX IF NOT EXISTS idx_guests_phone
ON guests(phone_number);
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
}
