import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/database/database_migrations.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database database;

  setUp(() {
    database = sqlite3.openInMemory();
  });

  tearDown(() {
    database.close();
  });

  test('migration 0 to 1 adds the reservation total column', () {
    database.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY,
        guest_id INTEGER NOT NULL,
        guest_count INTEGER NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL
      )
    ''');
    database.execute('PRAGMA user_version = 0');

    DatabaseMigrations.runMigrations(database);

    expect(DatabaseMigrations.currentDatabaseVersion, 1);
    final result = database.select('PRAGMA user_version');
    expect(result.first['user_version'], 1);
    final columns = database.select('PRAGMA table_info(reservations)');
    expect(columns.any((column) => column['name'] == 'total_grosze'), isTrue);
  });

  test('running migrations rejects a newer database version', () {
    database.execute('PRAGMA user_version = 999');

    expect(() => DatabaseMigrations.runMigrations(database), throwsStateError);
  });
}
