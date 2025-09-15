# Implementation Plan

- [-] 1. Setup Isar dependencies and infrastructure

  - Add Isar dependencies to pubspec.yaml (isar, isar_flutter_libs, isar_generator)
  - Create IsarDatabaseService singleton for database initialization
  - Implement database schema versioning and migration support
  - _Requirements: 1.1, 3.1_

- [ ] 2. Create Isar entity definitions with optimized indexing

  - [ ] 2.1 Create VaultEntity with proper annotations and indexes

    - Define VaultEntity class with @collection annotation
    - Add unique index on vaultId field
    - Implement IsarLinks for folder and note placement relationships
    - _Requirements: 2.1, 2.2, 5.2_

  - [ ] 2.2 Create FolderEntity with hierarchical relationship support

    - Define FolderEntity with parent-child IsarLink relationships
    - Add composite indexes for vault-scoped and hierarchical queries
    - Implement self-referencing parent-child relationships using IsarLinks
    - _Requirements: 2.1, 2.2, 5.2_

  - [ ] 2.3 Create NoteEntity and NotePageEntity with relationship links

    - Define NoteEntity with IsarLinks to pages and placement
    - Create NotePageEntity with optimized indexes for page queries
    - Add text search indexes on title and content fields
    - _Requirements: 2.1, 2.2, 5.1_

  - [ ] 2.4 Create LinkEntity with optimized relationship indexes

    - Define LinkEntity with composite indexes for efficient backlink queries
    - Add indexes on targetNoteId and sourcePageId for optimized link lookups
    - Implement IsarLinks to source pages and target notes
    - _Requirements: 2.1, 2.2, 5.2_

  - [ ] 2.5 Create NotePlacementEntity for vault tree management
    - Define NotePlacementEntity with vault and folder relationships
    - Add composite indexes for hierarchical and search queries
    - Implement IsarLinks to vault, folder, and note entities
    - _Requirements: 2.1, 2.2, 5.1_

- [ ] 3. Implement model mappers and conversion utilities

  - [ ] 3.1 Create VaultEntity ↔ VaultModel mappers

    - Implement toDomainModel() extension on VaultEntity
    - Implement toEntity() extension on VaultModel
    - Add unit tests for bidirectional conversion accuracy
    - _Requirements: 2.3, 4.4_

  - [ ] 3.2 Create FolderEntity ↔ FolderModel mappers

    - Implement mappers with proper nullable field handling
    - Handle parent-child relationship mapping correctly
    - Add comprehensive unit tests for edge cases
    - _Requirements: 2.3, 4.4_

  - [ ] 3.3 Create NoteEntity/PageEntity ↔ NoteModel/PageModel mappers

    - Implement complex nested relationship mapping
    - Handle enum conversions for source types and background types
    - Add performance tests for large note collections
    - _Requirements: 2.3, 4.4_

  - [ ] 3.4 Create LinkEntity ↔ LinkModel mappers
    - Implement mappers with proper relationship handling
    - Add validation for bounding box data integrity
    - Create unit tests for link relationship mapping
    - _Requirements: 2.3, 4.4_

- [ ] 4. Implement IsarDbTxnRunner for transaction management

  - Replace NoopDbTxnRunner with IsarDbTxnRunner implementation
  - Wrap all write operations in Isar write transactions
  - Add proper error handling and rollback mechanisms
  - Update provider configuration to use Isar transaction runner
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 5. Implement IsarVaultTreeRepository with optimized queries

  - [ ] 5.1 Implement basic CRUD operations for vaults

    - Create vault creation, reading, updating, and deletion methods
    - Implement watchVaults() stream using Isar reactive queries
    - Add proper error handling and validation
    - _Requirements: 4.1, 4.4_

  - [ ] 5.2 Implement folder hierarchy operations with IsarLinks

    - Create folder CRUD operations using efficient relationship loading
    - Implement getFolderAncestors() using IsarLink traversal
    - Add getFolderDescendants() with optimized recursive queries
    - Implement watchFolderChildren() with reactive Isar streams
    - _Requirements: 4.1, 4.4, 5.3_

  - [ ] 5.3 Implement note placement operations

    - Create note placement CRUD with vault tree integration
    - Implement moveMultipleNotes() using batch operations
    - Add registerExistingNote() for note tree registration
    - _Requirements: 4.1, 4.4, 5.4_

  - [ ] 5.4 Add optimized search functionality
    - Implement searchNotes() with Isar full-text search capabilities
    - Add composite queries for name and title searching
    - Optimize search performance with proper indexing
    - _Requirements: 4.1, 4.4, 5.1_

- [ ] 6. Implement IsarLinkRepository with advanced query optimization

  - [ ] 6.1 Implement basic link CRUD operations

    - Create link creation, reading, updating, and deletion methods
    - Implement watchByPage() and watchBacklinksToNote() reactive streams
    - Add proper relationship management with IsarLinks
    - _Requirements: 4.2, 4.4_

  - [ ] 6.2 Add optimized backlink and outgoing link queries

    - Implement getBacklinksForNote() with indexed queries
    - Create getOutgoingLinksForPage() using efficient filters
    - Add getBacklinkCountsForNotes() for bulk count operations
    - _Requirements: 4.2, 4.4, 5.2_

  - [ ] 6.3 Implement batch link operations
    - Create createMultipleLinks() using Isar batch operations
    - Implement deleteLinksForMultiplePages() with efficient bulk deletion
    - Add transaction support for atomic link operations
    - _Requirements: 4.2, 4.4, 5.4_

- [ ] 7. Implement IsarNotesRepository with performance optimizations

  - [ ] 7.1 Implement basic note CRUD operations

    - Create note creation, reading, updating, and deletion methods
    - Implement watchNotes() stream with Isar reactive queries
    - Add proper page relationship management using IsarLinks
    - _Requirements: 4.3, 4.4_

  - [ ] 7.2 Implement page management operations

    - Create page CRUD operations with note relationship handling
    - Implement efficient page ordering and management
    - Add batch page operations for performance optimization
    - _Requirements: 4.3, 4.4, 5.4_

  - [ ] 7.3 Add note search and filtering capabilities
    - Implement note filtering by various criteria using Isar queries
    - Add full-text search capabilities for note content
    - Optimize query performance with proper indexing strategies
    - _Requirements: 4.3, 4.4, 5.1_

- [ ] 8. Update provider configurations and dependency injection

  - Replace memory repository providers with Isar implementations
  - Update dbTxnRunnerProvider to use IsarDbTxnRunner
  - Add database initialization to app startup sequence
  - Ensure proper provider disposal and resource cleanup
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 9. Create comprehensive unit tests for Isar implementations

  - [ ] 9.1 Test entity mappers and conversions

    - Create unit tests for all entity ↔ model mappers
    - Test edge cases and nullable field handling
    - Verify bidirectional conversion accuracy
    - _Requirements: 6.3_

  - [ ] 9.2 Test repository implementations

    - Create unit tests for all repository CRUD operations
    - Test stream functionality and reactive updates
    - Verify transaction boundaries and error handling
    - _Requirements: 6.3_

  - [ ] 9.3 Test optimized query operations
    - Test search functionality and performance
    - Verify batch operations and bulk queries
    - Test relationship loading and traversal
    - _Requirements: 6.3, 5.1, 5.2_

- [ ] 10. Create integration tests and performance validation

  - [ ] 10.1 Test end-to-end database operations

    - Create integration tests for complete user workflows
    - Test data persistence across app restarts
    - Verify database initialization and migration
    - _Requirements: 1.3, 6.1_

  - [ ] 10.2 Performance benchmarking against memory implementation
    - Create performance tests for large datasets
    - Compare query performance between memory and Isar implementations
    - Validate search and relationship query optimization
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 11. Database migration and cleanup

  - [ ] 11.1 Add database schema migration support

    - Implement schema versioning for future updates
    - Add migration scripts for data format changes
    - Create backup and recovery mechanisms
    - _Requirements: 6.2, 6.3_

  - [ ] 11.2 Remove memory repository implementations
    - Delete MemoryVaultTreeRepository, MemoryLinkRepository, MemoryNotesRepository
    - Clean up unused memory-based code and dependencies
    - Update documentation to reflect Isar implementation
    - _Requirements: 4.1, 4.2, 4.3_

- [ ] 12. Final integration and testing
  - Run complete test suite to ensure no regressions
  - Perform end-to-end testing of all features with Isar backend
  - Validate performance improvements and optimization benefits
  - Update code generation with `fvm flutter packages pub run build_runner build`
  - _Requirements: 1.4, 4.4, 5.1, 5.2, 5.3, 5.4_
