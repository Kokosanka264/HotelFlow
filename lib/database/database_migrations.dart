import 'package:sqlite3/sqlite3.dart';

typedef DatabaseMigration = void Function(Database database);

class DatabaseMigrations {
  static const int currentDatabaseVersion = 2;
  static final Map<int, DatabaseMigration> migrations = {};

  static void setMigrations() {
    migrations
      ..clear()
      ..[1] = (database) {
        validateVersionOneSchema(database);
        final columns = database.select('PRAGMA table_info(reservations)');
        final hasNotes = columns.any((column) => column['name'] == 'notes');
        if (!hasNotes) {
          database.execute('''
          Alter TABLE reservations ADD COLUMN notes TEXT;
        ''');
        }
      };
  }

  static void validateVersionOneSchema(Database database) {
    final reservationsExists = database
        .select(
          "SELECT 1 FROM sqlite_master "
          "WHERE type = 'table' AND name = 'reservations'",
        )
        .isNotEmpty;
    if (!reservationsExists) {
      throw StateError(
        'Database migration failed: required reservations table is missing.',
      );
    }

    final columns = database.select('PRAGMA table_info(reservations)');
    final hasTotalGrosze = columns.any(
      (column) => column['name'] == 'total_grosze',
    );
    if (!hasTotalGrosze) {
      throw StateError(
        'Database migration failed: version 1 requires '
        'the reservations.total_grosze column.',
      );
    }
  }

  static void ensureNotesColumn(Database database) {
    validateVersionOneSchema(database);
    final columns = database.select('PRAGMA table_info(reservations)');
    final hasNotes = columns.any((column) => column['name'] == 'notes');
    if (!hasNotes) {
      database.execute('BEGIN TRANSACTION');
      try {
        database.execute('ALTER TABLE reservations ADD COLUMN notes TEXT');
        database.execute('COMMIT');
      } catch (_) {
        database.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  static void runMigration(Database database, int fromVersion) {
    setMigrations();
    final migration = migrations[fromVersion];
    if (migration == null) {
      throw StateError('Unknown database version: $fromVersion');
    }

    database.execute('BEGIN TRANSACTION');
    try {
      migration(database);
      final targetVersion = fromVersion + 1;
      database.execute('PRAGMA user_version = $targetVersion');
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  static void runMigrations(Database database) {
    setMigrations();
    int version = _databaseVersion(database);
    if (version < 1) {
      throw StateError(
        'Database version $version is not supported. '
        'Supported baseline versions start at 1.',
      );
    }
    if (version > currentDatabaseVersion) {
      throw StateError(
        'Database version is newer than expected. '
        'Please update the application.',
      );
    }

    while (version < currentDatabaseVersion) {
      runMigration(database, version);
      version = _databaseVersion(database);
    }

    ensureNotesColumn(database);
  }

  static int _databaseVersion(Database database) {
    final result = database.select('PRAGMA user_version');
    return result.first['user_version'] as int;
  }
}
