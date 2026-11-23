import 'package:sqlite3/sqlite3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'database_migrations.dart';

class DatabaseHelper {
  static Database? _database;
  static const List<String> requiredTables = [
    'rooms',
    'guests',
    'reservations',
    'reservation_rooms',
    'pricing_settings',
  ];
  static const int currentDatabaseVersion =
      DatabaseMigrations.currentDatabaseVersion;
  static void setDatabase() {
    if (isDatabaseEmpty || !hasExistingScheme) {
      createTables();
    }
    runMigrations();
  }

  static void setDatabaseVersion(int version) {
    if (version < 0) {
      throw ArgumentError('Database version cannot be negative.');
    }
    database.execute('PRAGMA user_version = $version;');
  }

  static void setMigrations() {
    DatabaseMigrations.setMigrations();
  }

  static void runMigration() {
    if (databaseVersion < currentDatabaseVersion) {
      DatabaseMigrations.runMigration(database, databaseVersion);
    }
  }

  static void runMigrations() {
    DatabaseMigrations.runMigrations(database);
  }

  static Database get database {
    if (_database == null) {
      throw StateError(
        'Database has not been initialized. Call createTables() first.',
      );
    }

    return _database!;
  }

  static int get databaseVersion {
    final result = database.select('PRAGMA user_version;');

    final version = result.first['user_version'] as int;
    return version;
  }

  static Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'hotel.db');
    _database = sqlite3.open(dbPath);
    _database!.execute('PRAGMA foreign_keys = ON;');
    setDatabase();
  }

  static bool get isDatabaseEmpty {
    final result = database.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return result.isEmpty;
  }

  static void closeDatabase() {
    _database?.close();
    _database = null;
  }

  static bool hasExistingTable(String tableName) {
    final bool hasTable = database.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name= ?",
      [tableName],
    ).isNotEmpty;
    return hasTable;
  }

  static bool get hasExistingScheme {
    return requiredTables.every((table) => hasExistingTable(table));
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
        total_grosze INTEGER NOT NULL DEFAULT 0 CHECK(total_grosze >= 0),
        CHECK(guest_count > 0),
        CHECK(CHECK_IN_DATE < CHECK_OUT_DATE),

        FOREIGN KEY (guest_id)
    REFERENCES guests(id)
    ON DELETE RESTRICT
      )
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS pricing_settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        capacity_two_grosze INTEGER NOT NULL CHECK(capacity_two_grosze > 0),
        capacity_four_grosze INTEGER NOT NULL CHECK(capacity_four_grosze > 0),
        extra_bed_grosze INTEGER NOT NULL CHECK(extra_bed_grosze >= 0)
      )
    ''');

    database.execute('''
      INSERT OR IGNORE INTO pricing_settings (
        id, capacity_two_grosze, capacity_four_grosze, extra_bed_grosze
      ) VALUES (1, 30000, 50000, 6000)
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

    ensureSearchIndexes();
    rebuildSearchIndexes();
  }

  static void ensureSearchIndexes([Database? targetDatabase]) {
    final target = targetDatabase ?? database;
    target.execute('''
      CREATE TABLE IF NOT EXISTS search_index_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    final reservationIndexVersion = target.select('''
      SELECT value
      FROM search_index_metadata
      WHERE key = 'reservation_search_version'
      ''');
    if (reservationIndexVersion.isEmpty ||
        reservationIndexVersion.first['value'] != '2') {
      target.execute('DROP TABLE IF EXISTS reservation_search');
    }
    target.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS guest_search USING fts5(
        guest_id UNINDEXED,
        guest_name,
        guest_surname,
        email,
        phone_number
      )
    ''');
    target.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS reservation_search USING fts5(
        reservation_id,
        guest_id UNINDEXED,
        guest_name,
        guest_surname,
        email,
        phone_number,
        guest_count,
        check_in_date,
        check_out_date
      )
    ''');
    target.execute('''
      INSERT OR REPLACE INTO search_index_metadata (key, value)
      VALUES ('reservation_search_version', '2')
    ''');
  }

  static void rebuildSearchIndexes([Database? targetDatabase]) {
    final target = targetDatabase ?? database;
    ensureSearchIndexes(target);

    final hasGuests = target
        .select(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'guests'",
        )
        .isNotEmpty;
    if (hasGuests) {
      target.execute('DELETE FROM guest_search');
      target.execute('''
        INSERT INTO guest_search (
          guest_id, guest_name, guest_surname, email, phone_number
        )
        SELECT id, guest_name, guest_surname, COALESCE(email, ''),
               COALESCE(phone_number, '')
        FROM guests
      ''');
    }

    final hasReservations = target
        .select(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'reservations'",
        )
        .isNotEmpty;
    if (hasReservations) {
      target.execute('DELETE FROM reservation_search');
      target.execute('''
        INSERT INTO reservation_search (
          reservation_id, guest_id, guest_name, guest_surname,
          email, phone_number, guest_count, check_in_date, check_out_date
        )
        SELECT reservations.id, reservations.guest_id,
               guests.guest_name, guests.guest_surname,
               COALESCE(guests.email, ''), COALESCE(guests.phone_number, ''),
               reservations.guest_count, reservations.check_in_date,
               reservations.check_out_date
        FROM reservations
        JOIN guests ON guests.id = reservations.guest_id
      ''');
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
