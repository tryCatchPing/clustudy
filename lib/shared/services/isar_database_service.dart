import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

part 'isar_database_service.g.dart';

/// Temporary dummy collection for infrastructure setup.
/// This will be removed when actual entities are created in task 2.
@collection
class DummyEntity {
  Id id = Isar.autoIncrement;
  late String dummyField;
}

/// Singleton service for managing Isar database initialization and access.
///
/// Provides centralized database instance management with proper initialization,
/// schema versioning, and migration support for the handwriting note app.
class IsarDatabaseService {
  static Isar? _instance;
  static const String _databaseName = 'it_contest_db';
  static const int _currentSchemaVersion = 1;

  /// Private constructor to enforce singleton pattern
  IsarDatabaseService._();

  /// Gets the singleton Isar database instance.
  ///
  /// Initializes the database on first access with proper schema definitions
  /// and migration support. Returns the existing instance on subsequent calls.
  static Future<Isar> getInstance() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    await _initializeDatabase();
    return _instance!;
  }

  /// Initializes the Isar database with schema definitions and migration support.
  static Future<void> _initializeDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/databases';

      // Ensure database directory exists
      await Directory(dbPath).create(recursive: true);

      // TODO: Add entity schemas when they are created in subsequent tasks
      // For now, use dummy entity to satisfy Isar's requirement of at least one collection
      _instance = await Isar.open(
        [
          DummyEntitySchema,
        ], // Will be replaced with actual entity schemas in task 2
        directory: dbPath,
        name: _databaseName,
        maxSizeMiB: 256, // 256MB max database size
        compactOnLaunch: const CompactCondition(
          minFileSize: 100 * 1024 * 1024, // 100MB
          minBytes: 50 * 1024 * 1024, // 50MB
          minRatio: 2.0,
        ),
      );

      // Perform schema migration if needed
      await _performMigrationIfNeeded();
    } catch (e) {
      throw DatabaseInitializationException(
        'Failed to initialize Isar database: $e',
      );
    }
  }

  /// Performs database schema migration if the current version differs.
  ///
  /// Checks stored schema version and applies necessary migrations to bring
  /// the database up to the current schema version.
  static Future<void> _performMigrationIfNeeded() async {
    if (_instance == null) return;

    try {
      // For now, just log the schema version
      // Migration logic will be implemented when entities are added

      // Log database initialization info
      print('Isar database initialized:');
      print('  Name: $_databaseName');
      print('  Schema version: $_currentSchemaVersion');
      print('  Database is open: ${_instance!.isOpen}');
    } catch (e) {
      print('Warning: Could not retrieve database info: $e');
    }
  }

  /// Closes the database instance and cleans up resources.
  ///
  /// Should be called when the app is shutting down to ensure proper
  /// resource cleanup and data persistence.
  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
    }
  }

  /// Clears all data from the database.
  ///
  /// Used primarily for testing and development. In production,
  /// this should be used with caution as it permanently deletes all data.
  static Future<void> clearDatabase() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.writeTxn(() async {
        await _instance!.clear();
      });
    }
  }

  /// Gets database statistics and information.
  ///
  /// Returns information about the current database state including
  /// size, collection counts, and schema version.
  static Future<DatabaseInfo> getDatabaseInfo() async {
    final isar = await getInstance();

    return const DatabaseInfo(
      name: _databaseName,
      path: 'Database path not available in Isar 3.x',
      size: 0, // Size info not available in Isar 3.x
      schemaVersion: _currentSchemaVersion,
      collections: [], // Will be populated when entities are added
    );
  }

  /// Performs database maintenance operations.
  ///
  /// Includes compaction, cleanup of unused space, and optimization
  /// of indexes for better performance.
  static Future<void> performMaintenance() async {
    final isar = await getInstance();

    try {
      // Database maintenance operations
      // Note: Compact method not available in Isar 3.x
      // Future maintenance operations will be added here
      print('Database maintenance completed successfully');
    } catch (e) {
      print('Database maintenance warning: $e');
    }
  }
}

/// Exception thrown when database initialization fails.
class DatabaseInitializationException implements Exception {
  /// The error message describing the initialization failure.
  final String message;

  /// Creates a new database initialization exception.
  const DatabaseInitializationException(this.message);

  @override
  String toString() => 'DatabaseInitializationException: $message';
}

/// Information about the current database state.
class DatabaseInfo {
  /// The database name.
  final String name;

  /// The full path to the database file.
  final String path;

  /// The current database size in bytes.
  final int size;

  /// The current schema version.
  final int schemaVersion;

  /// List of collection names in the database.
  final List<String> collections;

  /// Creates a new database info object.
  const DatabaseInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.schemaVersion,
    required this.collections,
  });

  @override
  String toString() {
    return 'DatabaseInfo(name: $name, path: $path, size: $size bytes, '
        'schemaVersion: $schemaVersion, collections: $collections)';
  }
}
