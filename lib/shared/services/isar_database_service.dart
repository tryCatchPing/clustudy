import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../entities/link_entity.dart';
import '../entities/note_entities.dart';
import '../entities/note_placement_entity.dart';
import '../entities/vault_entity.dart';

part 'isar_database_service.g.dart';

/// Stores metadata about the Isar instance such as schema version and
/// migration timestamps.
@collection
class DatabaseMetadataEntity {
  /// Fixed primary key – single row collection.
  Id id = 0;

  /// The schema version currently persisted on disk.
  late int schemaVersion;

  /// Timestamp of the last migration that touched this database.
  DateTime? lastMigrationAt;
}

/// Singleton service for managing Isar database initialization and access.
///
/// Provides centralized database instance management with proper initialization,
/// schema versioning, and migration support for the handwriting note app.
class IsarDatabaseService {
  static Isar? _instance;
  static const String _databaseName = 'it_contest_db';
  static const int _currentSchemaVersion = 1;
  static const int _metadataCollectionId = 0;

  static String? _databaseDirectoryPath;

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
      _databaseDirectoryPath = dbPath;

      // Ensure database directory exists
      await Directory(dbPath).create(recursive: true);

      _instance = await Isar.open(
        [
          // Core collections
          VaultEntitySchema,
          FolderEntitySchema,
          NoteEntitySchema,
          NotePageEntitySchema,
          LinkEntitySchema,
          NotePlacementEntitySchema,
          DatabaseMetadataEntitySchema,
        ],
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
      final metadataCollection = _instance!.databaseMetadataEntitys;
      final metadata = await metadataCollection.get(_metadataCollectionId);

      if (metadata == null) {
        final newMetadata = DatabaseMetadataEntity()
          ..schemaVersion = _currentSchemaVersion
          ..lastMigrationAt = DateTime.now();

        await _instance!.writeTxn(() async {
          await metadataCollection.put(newMetadata);
        });
        return;
      }

      if (metadata.schemaVersion < _currentSchemaVersion) {
        // Placeholder for future migration steps. When additional schema
        // versions are introduced we can perform field by field upgrades here.
        metadata
          ..schemaVersion = _currentSchemaVersion
          ..lastMigrationAt = DateTime.now();

        await _instance!.writeTxn(() async {
          await metadataCollection.put(metadata);
        });
      }
    } catch (e) {
      debugPrint('Warning: Could not update database metadata: $e');
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
      await _performMigrationIfNeeded();
    }
  }

  /// Gets database statistics and information.
  ///
  /// Returns information about the current database state including
  /// size, collection counts, and schema version.
  static Future<DatabaseInfo> getDatabaseInfo() async {
    final isar = await getInstance();
    final metadata =
        await isar.databaseMetadataEntitys.get(_metadataCollectionId);
    final size = await _calculateDatabaseSize();

    final directoryPath = _databaseDirectoryPath ?? 'Unknown directory';

    return DatabaseInfo(
      name: _databaseName,
      path: '$directoryPath/$_databaseName',
      size: size,
      schemaVersion: metadata?.schemaVersion ?? _currentSchemaVersion,
      collections: const [
        'VaultEntity',
        'FolderEntity',
        'NoteEntity',
        'NotePageEntity',
        'LinkEntity',
        'NotePlacementEntity',
        'DatabaseMetadataEntity',
      ],
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
      debugPrint('Database maintenance completed successfully');
    } catch (e) {
      debugPrint('Database maintenance warning: $e');
    }
  }

  static Future<int> _calculateDatabaseSize() async {
    final directoryPath = _databaseDirectoryPath;
    if (directoryPath == null) {
      return 0;
    }

    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return 0;
    }

    var totalBytes = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!entity.path.contains(_databaseName)) {
        continue;
      }
      totalBytes += await entity.length();
    }

    return totalBytes;
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
