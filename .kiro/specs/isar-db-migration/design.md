# Design Document

## Overview

This design outlines the migration from memory-based repository implementations to IsarDB, a high-performance NoSQL database for Flutter. The migration will maintain existing interface contracts while providing persistent storage, improved performance, and better scalability for the handwriting note-taking application.

IsarDB was chosen for its excellent Flutter integration, high performance, type safety, and built-in support for complex queries and relationships. It provides automatic code generation, efficient indexing, and reactive streams that align well with the existing Riverpod architecture.

## Architecture

### Database Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│                Repository Interfaces                       │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐  │
│  │VaultTreeRepository│ │  LinkRepository │ │NotesRepository│  │
│  └─────────────────┘ └─────────────────┘ └──────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                Isar Repository Implementations              │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐  │
│  │IsarVaultTreeRepo│ │  IsarLinkRepo   │ │IsarNotesRepo │  │
│  └─────────────────┘ └─────────────────┘ └──────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    IsarDB Layer                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐  │
│  │   VaultEntity   │ │   LinkEntity    │ │  NoteEntity  │  │
│  │   FolderEntity  │ │                 │ │ PageEntity   │  │
│  │NotePlacementEnt │ │                 │ │              │  │
│  └─────────────────┘ └─────────────────┘ └──────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                 Transaction Management                      │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              IsarDbTxnRunner                            │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Model-Entity Mapping Strategy

The design uses a dual-model approach:

- **Domain Models**: Existing models (VaultModel, NoteModel, etc.) remain unchanged for business logic
- **Isar Entities**: New Isar-specific entities with annotations for database operations
- **Mappers**: Conversion functions between domain models and Isar entities

This approach ensures:

- Minimal changes to existing business logic
- Clean separation between domain and persistence layers
- Easy testing and mocking capabilities

## Components and Interfaces

### 1. Dependencies and Setup

**New Dependencies Required:**

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

dev_dependencies:
  isar_generator: ^3.1.0+1
```

### 2. Isar Entities

#### VaultEntity

```dart
@collection
class VaultEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String vaultId;

  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  final folders = IsarLinks<FolderEntity>();
  final notePlacements = IsarLinks<NotePlacementEntity>();
}
```

#### FolderEntity

```dart
@collection
class FolderEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String folderId;

  late String vaultId;
  late String name;
  String? parentFolderId;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  final vault = IsarLink<VaultEntity>();
  final parentFolder = IsarLink<FolderEntity>();
  final childFolders = IsarLinks<FolderEntity>();
  final notePlacements = IsarLinks<NotePlacementEntity>();
}
```

#### NoteEntity

```dart
@collection
class NoteEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String noteId;

  late String title;
  @Enumerated(EnumType.name)
  late NoteSourceType sourceType;
  String? sourcePdfPath;
  int? totalPdfPages;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  final pages = IsarLinks<NotePageEntity>();
  final placement = IsarLink<NotePlacementEntity>();
}
```

#### NotePageEntity

```dart
@collection
class NotePageEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String pageId;

  late String noteId;
  late int pageNumber;
  late String jsonData;

  @Enumerated(EnumType.name)
  late PageBackgroundType backgroundType;
  String? backgroundPdfPath;
  int? backgroundPdfPageNumber;
  double? backgroundWidth;
  double? backgroundHeight;
  String? preRenderedImagePath;
  late bool showBackgroundImage;

  // Relationships
  final note = IsarLink<NoteEntity>();
  final outgoingLinks = IsarLinks<LinkEntity>();
}
```

#### LinkEntity

```dart
@collection
class LinkEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String linkId;

  late String sourceNoteId;
  late String sourcePageId;
  late String targetNoteId;

  late double bboxLeft;
  late double bboxTop;
  late double bboxWidth;
  late double bboxHeight;

  String? label;
  String? anchorText;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relationships
  final sourcePage = IsarLink<NotePageEntity>();
  final targetNote = IsarLink<NoteEntity>();
}
```

#### NotePlacementEntity

```dart
@collection
class NotePlacementEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String noteId;

  late String vaultId;
  String? parentFolderId;
  late String name;

  // Relationships
  final vault = IsarLink<VaultEntity>();
  final parentFolder = IsarLink<FolderEntity>();
  final note = IsarLink<NoteEntity>();
}
```

### 3. Database Service

#### IsarDatabaseService

```dart
class IsarDatabaseService {
  static Isar? _instance;

  static Future<Isar> getInstance() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        VaultEntitySchema,
        FolderEntitySchema,
        NoteEntitySchema,
        NotePageEntitySchema,
        LinkEntitySchema,
        NotePlacementEntitySchema,
      ],
      directory: dir.path,
      name: 'it_contest_db',
    );

    return _instance!;
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
```

### 4. Transaction Runner

#### IsarDbTxnRunner

```dart
class IsarDbTxnRunner implements DbTxnRunner {
  final Isar _isar;

  IsarDbTxnRunner(this._isar);

  @override
  Future<T> write<T>(Future<T> Function() action) async {
    return await _isar.writeTxn(() async {
      return await action();
    });
  }
}
```

### 5. Repository Implementations

#### IsarVaultTreeRepository

- Implements VaultTreeRepository interface
- Uses IsarLinks for efficient relationship queries
- Provides reactive streams using Isar's watch functionality
- Handles hierarchical folder operations with proper constraint checking

#### IsarLinkRepository

- Implements LinkRepository interface
- Uses compound indexes for efficient page-based and note-based queries
- Maintains reactive streams for link changes
- Optimizes bulk operations using Isar batch operations

#### IsarNotesRepository

- Implements NotesRepository interface
- Manages note-page relationships using IsarLinks
- Handles JSON sketch data efficiently
- Provides optimized queries for note listing and searching

## Data Models

### Model Mappers

Each entity will have corresponding mapper functions:

```dart
// Example for VaultEntity
extension VaultEntityMapper on VaultEntity {
  VaultModel toDomainModel() {
    return VaultModel(
      vaultId: vaultId,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension VaultModelMapper on VaultModel {
  VaultEntity toEntity() {
    return VaultEntity()
      ..vaultId = vaultId
      ..name = name
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}
```

### Relationship Management

IsarLinks will be used for managing relationships:

- **One-to-Many**: Vault → Folders, Note → Pages
- **Many-to-One**: Folder → Parent Folder, Page → Note
- **Many-to-Many**: Not used in current domain model

## Error Handling

### Database Initialization

- Graceful fallback to memory repositories if Isar initialization fails
- Clear error messages for debugging
- Retry mechanisms for transient failures

### Transaction Errors

- Automatic rollback on transaction failures
- Proper error propagation to calling code
- Logging for debugging purposes

### Data Corruption

- Schema validation on startup
- Backup and recovery mechanisms
- Data integrity checks

## Testing Strategy

### Unit Testing

- Mock Isar instances for repository testing
- Separate testing of mappers and business logic
- Transaction boundary testing

### Integration Testing

- End-to-end database operations
- Performance benchmarking against memory implementation
- Data migration testing

### Test Database Management

- Separate test database instances
- Cleanup mechanisms between tests
- Test data factories for consistent test scenarios

## Migration Strategy

### Phase 1: Setup and Infrastructure

- Add Isar dependencies
- Create entity definitions and schemas
- Implement database service and transaction runner

### Phase 2: Repository Implementation

- Implement Isar repository classes
- Create model mappers
- Add comprehensive unit tests

### Phase 3: Integration and Testing

- Replace memory repositories with Isar implementations
- Run integration tests
- Performance validation

### Phase 4: Optimization and Cleanup

- Optimize queries and indexes
- Remove memory repository implementations
- Documentation updates

## Isar-Specific Optimizations

### 1. Search Functionality Migration

**Current State**: Search logic is scattered across services with inefficient in-memory filtering.

**Isar Optimization**:

- Add `searchNotes(String query, {String? vaultId})` method to VaultTreeRepository interface
- Implement full-text search using Isar's efficient indexing:

```dart
// IsarVaultTreeRepository implementation
@override
Future<List<NotePlacement>> searchNotes(String query, {String? vaultId}) async {
  final isar = await IsarDatabaseService.getInstance();

  return await isar.notePlacementEntitys
    .filter()
    .optional(vaultId != null, (q) => q.vaultIdEqualTo(vaultId!))
    .group((q) => q
      .nameContains(query, caseSensitive: false)
      .or()
      .note((noteQ) => noteQ.titleContains(query, caseSensitive: false))
    )
    .findAll()
    .then((entities) => entities.map((e) => e.toDomainModel()).toList());
}
```

- Add text search indexes on name and title fields
- VaultNotesService becomes a simple delegation layer

### 2. Backlink/Link Query Optimization

**Current State**: Inefficient stream-based link lookups with manual filtering.

**Isar Optimization**:

- Enhanced LinkRepository interface with optimized query methods:

```dart
abstract class LinkRepository {
  // Existing methods...

  // New optimized methods
  Future<List<LinkModel>> getBacklinksForNote(String noteId);
  Future<List<LinkModel>> getOutgoingLinksForPage(String pageId);
  Future<Map<String, int>> getBacklinkCountsForNotes(List<String> noteIds);
  Stream<List<LinkModel>> watchLinksByNoteId(String noteId);
}
```

- IsarLinkRepository implementation with indexed queries:

```dart
@override
Future<List<LinkModel>> getBacklinksForNote(String noteId) async {
  final isar = await IsarDatabaseService.getInstance();

  final entities = await isar.linkEntitys
    .filter()
    .targetNoteIdEqualTo(noteId)
    .findAll();

  return entities.map((e) => e.toDomainModel()).toList();
}

@override
Future<Map<String, int>> getBacklinkCountsForNotes(List<String> noteIds) async {
  final isar = await IsarDatabaseService.getInstance();

  final counts = <String, int>{};
  for (final noteId in noteIds) {
    final count = await isar.linkEntitys
      .filter()
      .targetNoteIdEqualTo(noteId)
      .count();
    counts[noteId] = count;
  }
  return counts;
}
```

- Add composite indexes for efficient link queries:

```dart
@collection
class LinkEntity {
  // ... existing fields

  @Index()
  late String targetNoteId;  // For backlink queries

  @Index()
  late String sourcePageId; // For outgoing link queries

  @Index(composite: [CompositeIndex('sourceNoteId')])
  late String sourcePageId; // For note-level link queries
}
```

### 3. Hierarchical Structure Navigation Optimization

**Current State**: Recursive traversal with multiple repository calls.

**Isar Optimization**:

- Leverage IsarLinks for efficient relationship traversal:

```dart
// Enhanced VaultTreeRepository interface
abstract class VaultTreeRepository {
  // Existing methods...

  // New optimized hierarchy methods
  Future<List<FolderModel>> getFolderAncestors(String folderId);
  Future<List<FolderModel>> getFolderDescendants(String folderId);
  Future<FolderModel?> getFolderWithChildren(String folderId);
  Stream<VaultTreeNode> watchVaultTree(String vaultId);
}
```

- IsarVaultTreeRepository with relationship loading:

```dart
@override
Future<List<FolderModel>> getFolderAncestors(String folderId) async {
  final isar = await IsarDatabaseService.getInstance();
  final ancestors = <FolderEntity>[];

  var currentFolder = await isar.folderEntitys
    .filter()
    .folderIdEqualTo(folderId)
    .findFirst();

  while (currentFolder != null && currentFolder.parentFolderId != null) {
    await currentFolder.parentFolder.load(); // Efficient link loading
    currentFolder = currentFolder.parentFolder.value;
    if (currentFolder != null) {
      ancestors.add(currentFolder);
    }
  }

  return ancestors.map((e) => e.toDomainModel()).toList();
}

@override
Future<FolderModel?> getFolderWithChildren(String folderId) async {
  final isar = await IsarDatabaseService.getInstance();

  final folder = await isar.folderEntitys
    .filter()
    .folderIdEqualTo(folderId)
    .findFirst();

  if (folder != null) {
    await folder.childFolders.load(); // Load all children in one operation
    await folder.notePlacements.load(); // Load all note placements
  }

  return folder?.toDomainModel();
}
```

### 4. Batch Operations Optimization

**Current State**: Individual operations for bulk changes.

**Isar Optimization**:

- Implement efficient batch operations:

```dart
// Enhanced repository interfaces
abstract class VaultTreeRepository {
  // Existing methods...

  Future<void> moveMultipleNotes(List<String> noteIds, String? newParentFolderId);
  Future<void> deleteMultipleFolders(List<String> folderIds);
}

abstract class LinkRepository {
  // Existing methods...

  Future<void> createMultipleLinks(List<LinkModel> links);
  Future<int> deleteLinksForMultiplePages(List<String> pageIds);
}
```

- Batch implementation using Isar transactions:

```dart
@override
Future<void> moveMultipleNotes(List<String> noteIds, String? newParentFolderId) async {
  final isar = await IsarDatabaseService.getInstance();

  await isar.writeTxn(() async {
    final placements = await isar.notePlacementEntitys
      .filter()
      .anyOf(noteIds, (q, noteId) => q.noteIdEqualTo(noteId))
      .findAll();

    for (final placement in placements) {
      placement.parentFolderId = newParentFolderId;
    }

    await isar.notePlacementEntitys.putAll(placements);
  });
}
```

### 5. Reactive Query Optimization

**Current State**: Manual stream management with memory-based filtering.

**Isar Optimization**:

- Use Isar's built-in reactive queries:

```dart
@override
Stream<List<VaultItem>> watchFolderChildren(String vaultId, {String? parentFolderId}) {
  return IsarDatabaseService.getInstance().then((isar) {
    // Combine folder and note placement streams efficiently
    final folderStream = isar.folderEntitys
      .filter()
      .vaultIdEqualTo(vaultId)
      .and()
      .optional(parentFolderId != null,
        (q) => q.parentFolderIdEqualTo(parentFolderId))
      .watch(fireImmediately: true);

    final noteStream = isar.notePlacementEntitys
      .filter()
      .vaultIdEqualTo(vaultId)
      .and()
      .optional(parentFolderId != null,
        (q) => q.parentFolderIdEqualTo(parentFolderId))
      .watch(fireImmediately: true);

    return Rx.combineLatest2(folderStream, noteStream, (folders, notes) {
      final items = <VaultItem>[];
      items.addAll(folders.map((f) => VaultItem.folder(f.toDomainModel())));
      items.addAll(notes.map((n) => VaultItem.note(n.toDomainModel())));
      return items..sort((a, b) => a.name.compareTo(b.name));
    });
  }).asStream().switchMap((stream) => stream);
}
```

### 6. Advanced Indexing Strategy

**Optimized Index Configuration**:

```dart
@collection
class NoteEntity {
  // ... existing fields

  @Index(type: IndexType.value)
  late String title; // For text search

  @Index(composite: [CompositeIndex('createdAt')])
  late String vaultId; // For vault-scoped queries with sorting
}

@collection
class NotePlacementEntity {
  // ... existing fields

  @Index(type: IndexType.value)
  late String name; // For search functionality

  @Index(composite: [CompositeIndex('parentFolderId')])
  late String vaultId; // For hierarchical queries
}

@collection
class LinkEntity {
  // ... existing fields

  @Index(composite: [CompositeIndex('targetNoteId')])
  late String sourceNoteId; // For bidirectional link queries
}
```

## Performance Considerations

### Query Performance

- Leverage Isar's automatic query optimization
- Use composite indexes for multi-field queries
- Implement efficient pagination with offset/limit
- Cache frequently accessed relationship data

### Memory Management

- Proper disposal of Isar streams and resources
- Use lazy loading for large relationship collections
- Implement efficient batch operations for bulk changes
- Monitor and optimize database size with regular maintenance

### Concurrency Optimization

- Utilize Isar's built-in thread safety
- Implement read-heavy operations outside transactions
- Use Isar's efficient multi-isolate support for background operations
