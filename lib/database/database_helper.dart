import 'package:sqlite3/sqlite3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
class DatabaseHelper {
  static Database? _database;

  static Database get database{
    if(_database == null){
      throw StateError('Database has not been initialized. Call createTables() first.');
    } 
      
    return _database!;
  }
  static Future<void> initialize() async{
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
      CREATE INDEX IF NOT EXISTS idx_reservations_room_DATES ON reservations (room_id, check_in_date, check_out_date)
    ''');
    final tables = database.select("SELECT name FROM sqlite_master WHERE type='table'");
    for (final table in tables) {
      print(table['name']);
    }
  }
 
}