# Settings contract

Frozen keys and types for app-wide settings. Any changes require contract updates.

## Keys and Types

- `encryptionEnabled: bool`
- `backupDailyAt: String` — format `HH:mm` 24h
- `backupRetentionDays: int`
- `recycleRetentionDays: int`
- `keychainAlias?: String`
- `lastBackupAt?: DateTime` (indexed)
- `dataVersion?: int` — schema/migration version
- `backupRequireWifi?: bool`
- `backupOnlyWhenCharging?: bool`
- `pdfCacheMaxMB?: int`

## Behavior

- `backupDailyAt` schedules daily backup; runner must persist `lastBackupAt` after success.
- `dataVersion` is used by migration runner to decide when to apply migrations.

# Settings Contract

Frozen keys and meanings used across backup/encryption and cache policies.

- `encryptionEnabled: bool`
- `backupDailyAt: string (HH:mm)`
- `backupRetentionDays: int`
- `recycleRetentionDays: int`
- `keychainAlias: string?`
- `dataVersion: int?`
- `backupRequireWifi?: bool`
- `backupOnlyWhenCharging?: bool`
- `pdfCacheMaxMB?: int`

Backup/Encryption:
- `runFullBackup({includeFiles, encrypt})` zips Isar snapshot (+optionally notes files minus `pdf_cache`) and optionally AES-encrypts output using a key from secure storage.
- AES key storage alias: `backup_aes_key_v1` in Keychain/Keystore.

Cache Exclude Convention:
- Exclude `notes/*/pdf_cache/*` from backups.


