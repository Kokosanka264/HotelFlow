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

  test('migration 1 to 2 adds the reservation notes column', () {
    database.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY,
        guest_id INTEGER NOT NULL,
        guest_count INTEGER NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        total_grosze INTEGER NOT NULL DEFAULT 0
      )
    ''');
    database.execute('PRAGMA user_version = 1');

    DatabaseMigrations.runMigrations(database);

    expect(DatabaseMigrations.currentDatabaseVersion, 2);
    final result = database.select('PRAGMA user_version');
    expect(result.first['user_version'], 2);
    final columns = database.select('PRAGMA table_info(reservations)');
    expect(columns.any((column) => column['name'] == 'notes'), isTrue);
  });

  test('migration 1 to 2 keeps an existing notes column', () {
    database.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY,
        total_grosze INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');
    database.execute('PRAGMA user_version = 1');

    DatabaseMigrations.runMigrations(database);

    final result = database.select('PRAGMA user_version');
    expect(result.first['user_version'], 2);
    final columns = database.select('PRAGMA table_info(reservations)');
    expect(columns.where((column) => column['name'] == 'notes').length, 1);
  });

  test('a database at current version does not run migrations', () {
    database.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY,
        total_grosze INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');
    database.execute('PRAGMA user_version = 2');

    expect(() => DatabaseMigrations.runMigrations(database), returnsNormally);
    final result = database.select('PRAGMA user_version');
    expect(result.first['user_version'], 2);
  });

  test('unsupported version 0 is reported', () {
    database.execute('PRAGMA user_version = 0');

    expect(
      () => DatabaseMigrations.runMigrations(database),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('Supported baseline versions start at 1'),
        ),
      ),
    );
  });

  test('database at version 2 repairs a missing notes column', () {
    database.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY,
        total_grosze INTEGER NOT NULL DEFAULT 0
      )
    ''');
    database.execute('PRAGMA user_version = 2');

    DatabaseMigrations.runMigrations(database);

    final columns = database.select('PRAGMA table_info(reservations)');
    expect(columns.any((column) => column['name'] == 'notes'), isTrue);
  });

  test('missing reservations table is reported clearly', () {
    database.execute('PRAGMA user_version = 1');

    expect(
      () => DatabaseMigrations.runMigrations(database),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('required reservations table is missing'),
        ),
      ),
    );
  });

  test('version 1 requires the default total_grosze column', () {
    database.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY
      )
    ''');
    database.execute('PRAGMA user_version = 1');

    expect(
      () => DatabaseMigrations.runMigrations(database),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('requires the reservations.total_grosze column'),
        ),
      ),
    );
  });

  test('running migrations rejects a newer database version', () {
    database.execute('PRAGMA user_version = 999');

    expect(() => DatabaseMigrations.runMigrations(database), throwsStateError);
  });
}
