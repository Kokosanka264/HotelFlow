import 'package:sqlite3/sqlite3.dart';

typedef DatabaseMigration = void Function(Database database);

class DatabaseMigrations {
  static const int currentDatabaseVersion = 1;
  static final Map<int, DatabaseMigration> migrations = {};

  static void setMigrations() {
    migrations
      ..clear();
      
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
  }

  static int _databaseVersion(Database database) {
    final result = database.select('PRAGMA user_version');
    return result.first['user_version'] as int;
  }
}
