# PdfCache API Contract

This document defines the public API for PDF cache and thumbnails. Breaking changes require contract change coordination.

## API

```dart
class PdfCache {
  static Future<void> invalidate({required int noteId, int? pageIndex});
  static String path({required int noteId, required int pageIndex});
  static Future<void> renderAndCache({required int noteId, required int pageIndex, int dpi = 144});
}
```

- `invalidate` removes cache entries (all pages or a single page when `pageIndex` provided) and updates `PdfCacheMeta` accordingly.
- `path` returns the absolute cache file path for a given noteId/pageIndex (must be deterministic and stable).
- `renderAndCache` renders the PDF page (and optional canvas composite) and persists the result; it must upsert `PdfCacheMeta` with `renderedAt`, `dpi`, `sizeBytes?`, and update `lastAccessAt?`.

## Global LRU-like capacity

- A global capacity limit in MB governs eviction.
- Eviction policy: remove least-recently-accessed pages when above capacity; never evict files currently in-flight.

## Exclusions for Backup

- Cached files under the cache root path MUST be excluded from backups. Backup logic should use this path to skip.

PDF Cache and Thumbnails Policy (h)

Scope
- Ownership: /lib/pdfcache/*, /lib/thumbnails/*
- Depends on: a(PdfCacheMeta schema), g(canvas composition data)

Public API (contract)
```dart
class PdfCache {
  static Future<void> invalidate({required int noteId, int? pageIndex});
  static String path({required int noteId, required int pageIndex});
  static Future<void> renderAndCache({required int noteId, required int pageIndex, int dpi = 144});
}
```

Path Convention
- Relative to application documents directory
- `notes/{noteId}/pdf_cache/{pageIndex}@{dpi}.png`

PdfCacheMeta (v1.0)
- Fields: id, noteId, pageIndex, cachePath, dpi, renderedAt
- Indexes: noteId, pageIndex, renderedAt
- Upsert on render, delete on invalidate

LRU-like Capacity Guard
- SettingsEntity.pdfCacheMaxMB (default 512)
- After each render, compute total size and evict oldest by renderedAt until under cap

Invalidate Behavior
- If pageIndex omitted: invalidate all entries for the note
- Delete files first, then delete meta rows

Thumbnail Policy
- First iteration: return base PDF render as thumbnail
- Future: compose canvas strokes over PDF image (depends on g)

Feature Flag
- `feature.pdfCacheLRU` may guard capacity enforcement (default ON in current draft)

Change Log
- 1.0.0: Initial contract established


