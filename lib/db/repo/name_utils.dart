import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

/// Utilities for enforcing unique lower-cased names and generating
/// collision-free labels for Notes and Folders.
///
/// Contract (do not change signatures without coordination):
/// - Future<bool> existsFolderNameLower(int vaultId, String lower);
/// - Future<bool> existsNoteNameLower(int vaultId, int folderId, String lower);
/// - Future<String> generateUniqueNoteName(int vaultId, int folderId, String baseLabel);
class NameUtils {
  const NameUtils._();

  /// Returns true if a Folder exists in the vault with the given lower-cased name.
  static Future<bool> existsFolderNameLower(int vaultId, String lower) async {
    final isar = await IsarDb.instance.open();
    final normalized = lower.toLowerCase();

    // Prefer unique composite index lookup if available (nameLowerForVaultUnique + vaultId)
    Folder? found;
    try {
      found = await isar.folders
          .getByNameLowerForVaultUnique(normalized, vaultId);
    } on IsarError {
      // Fallback to filter in case codegen name changes; still correct though not index-optimized.
      found = await isar.folders
          .filter()
          .vaultIdEqualTo(vaultId)
          .nameLowerForVaultUniqueEqualTo(normalized)
          .findFirst();
    }
    return found != null;
  }

  /// Returns true if a Note exists within (vaultId, folderId) with the given lower-cased name.
  /// folderId <= 0 is treated as root (null) for uniqueness scope.
  static Future<bool> existsNoteNameLower(
    int vaultId,
    int folderId,
    String lower,
  ) async {
    final isar = await IsarDb.instance.open();
    final normalized = lower.toLowerCase();
    final int? scopedFolderId = folderId > 0 ? folderId : null;

    Note? found;
    try {
      found = await isar.notes.getByNameLowerForParentUnique(
        normalized,
        vaultId,
        scopedFolderId,
      );
    } on IsarError {
      found = await isar.notes
          .filter()
          .vaultIdEqualTo(vaultId)
          .and()
          .folderIdEqualTo(scopedFolderId)
          .and()
          .nameLowerForParentUniqueEqualTo(normalized)
          .findFirst();
    }
    return found != null;
  }

  /// Generate a unique note name under (vaultId, folderId) by appending " (n)" if necessary.
  /// - Starts with [baseLabel] if available.
  /// - Then tries "baseLabel (2)", "baseLabel (3)", ...
  static Future<String> generateUniqueNoteName(
    int vaultId,
    int folderId,
    String baseLabel,
  ) async {
    final trimmed = baseLabel.trim();
    if (trimmed.isEmpty) {
      // Provide a sensible default if base is empty
      return await _firstAvailableName(vaultId, folderId, 'Untitled');
    }
    // Prefer the base label as-is if available.
    final baseLower = trimmed.toLowerCase();
    final existsBase =
        await existsNoteNameLower(vaultId, folderId, baseLower);
    if (!existsBase) return trimmed;

    // Try with numeric suffixes starting from 2.
    for (int n = 2; n < 100000; n++) {
      final candidate = '$trimmed ($n)';
      final candidateLower = candidate.toLowerCase();
      final exists = await existsNoteNameLower(
        vaultId,
        folderId,
        candidateLower,
      );
      if (!exists) return candidate;
    }
    // Extremely unlikely fallback
    return '${trimmed}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<String> _firstAvailableName(
    int vaultId,
    int folderId,
    String seed,
  ) async {
    final baseLower = seed.toLowerCase();
    if (!await existsNoteNameLower(vaultId, folderId, baseLower)) {
      return seed;
    }
    for (int n = 2; n < 100000; n++) {
      final candidate = '$seed ($n)';
      if (!await existsNoteNameLower(
        vaultId,
        folderId,
        candidate.toLowerCase(),
      )) {
        return candidate;
      }
    }
    return '${seed}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// -------- Public contract (top-level functions) --------

Future<bool> existsFolderNameLower(int vaultId, String lower) {
  return NameUtils.existsFolderNameLower(vaultId, lower);
}

Future<bool> existsNoteNameLower(int vaultId, int folderId, String lower) {
  return NameUtils.existsNoteNameLower(vaultId, folderId, lower);
}

Future<String> generateUniqueNoteName(
  int vaultId,
  int folderId,
  String baseLabel,
) {
  return NameUtils.generateUniqueNoteName(vaultId, folderId, baseLabel);
}


