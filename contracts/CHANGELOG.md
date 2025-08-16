# Contracts Changelog

All contract-affecting changes must be recorded here.

## 2025-08-14

- Initial freeze of schema fields/indexes for Vault, Folder, Note, CanvasData, PageSnapshot, LinkEntity, GraphEdge, PdfCacheMeta, SettingsEntity.
- Added API contract for PdfCache (path/invalidate/renderAndCache).
- Documented RectNorm constraints (0..1 and x0<x1, y0<y1).
- Settings keys/types standardized.

# Contracts Change Log

- v1.1: Added PdfCacheMeta.sizeBytes, PdfCacheMeta.lastAccessAt; introduced Settings policy flags.
- v1.0: Initial schema contract published.

