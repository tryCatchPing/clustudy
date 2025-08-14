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


