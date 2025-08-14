# Data schema contract

This document freezes public schema fields and indexes that other teams depend on. Any breaking change MUST go through `contracts/CHANGELOG.md` and coordinated merge.

## Name lower rules and indexes

- Vault
  - Field: `nameLowerUnique: String`
  - Index: unique, case-insensitive

- Folder
  - Field: `nameLowerForVaultUnique: String`
  - Unique scope: `(vaultId, lower(name))`
  - Index: composite unique [vaultId + nameLowerForVaultUnique], case-insensitive

- Note
  - Field: `nameLowerForParentUnique: String`
  - Unique scope: `(vaultId, folderId, lower(name))`
  - Index: composite unique [vaultId + folderId + nameLowerForParentUnique], case-insensitive

## RectNorm

Normalized rectangle used for link regions.

- Domain: [0..1]
- Invariants: `x0 < x1`, `y0 < y1`
- Validation must clamp and assert above invariants when persisted

## CanvasData

- Field: `schemaVersion: String` — NOT NULL
- Indexes: `noteId`, unique `pageId`

## PageSnapshot

- Fields: `pageId`, `schemaVersion`, `json`, `createdAt`
- Index: `pageId`, `createdAt` (used by retention triggers)

## LinkEntity

- Key fields
  - `vaultId`, `sourceNoteId`, `sourcePageId`
  - `x0, y0, x1, y1` — RectNorm coordinates
  - `targetNoteId?`, `label?`
  - `dangling: bool` — true if target note is soft-deleted
  - `createdAt`, `updatedAt`

## GraphEdge

- Fields: `vaultId`, `fromNoteId`, `toNoteId`, `createdAt`
- Indexes: `vaultId`, `fromNoteId`, `toNoteId`
- Deletion policy: when a `LinkEntity` is deleted, its corresponding `GraphEdge` must be deleted synchronously

## PdfCacheMeta (v1.1 recommended)

- Fields (frozen):
  - `id`
  - `noteId`
  - `pageIndex`
  - `cachePath`
  - `dpi`
  - `renderedAt`
  - `sizeBytes?`
  - `lastAccessAt?`
- Index recommendations: `noteId`, `pageIndex`, `lastAccessAt`

## SettingsEntity

- Fields:
  - `encryptionEnabled: bool`
  - `backupDailyAt: String` (e.g., `"02:00"` 24h)
  - `backupRetentionDays: int`
  - `recycleRetentionDays: int`
  - `keychainAlias?: String`
  - `lastBackupAt?: DateTime` (indexed)
  - `dataVersion?: int`
  - `backupRequireWifi?: bool`
  - `backupOnlyWhenCharging?: bool`
  - `pdfCacheMaxMB?: int`

# Schema Contract (Frozen Interfaces)

## Name Lowering & Uniqueness
- Vault: `nameLowerUnique` UNIQUE
- Folder: UNIQUE(`vaultId`, lower(`name`)) via `nameLowerForVaultUnique`
- Note: UNIQUE(`vaultId`, `folderId`, lower(`name`)) via `nameLowerForParentUnique`

## RectNorm
- Normalized rectangle in [0,1]: `x0<x1`, `y0<y1`.

## PdfCacheMeta v1.1
- Fields: `id`, `noteId`, `pageIndex`, `cachePath`, `dpi`, `renderedAt`, `sizeBytes?`, `lastAccessAt?`

## Settings Keys
- `encryptionEnabled: bool`
- `backupDailyAt: HH:mm`
- `backupRetentionDays: int`
- `recycleRetentionDays: int`
- `keychainAlias: string?`
- `dataVersion: int?`
- Policy: `backupRequireWifi?: bool`, `backupOnlyWhenCharging?: bool`, `pdfCacheMaxMB?: int`


