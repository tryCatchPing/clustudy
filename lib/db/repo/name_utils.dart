import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

/// Utilities for enforcing unique lower-cased names and generating
/// collision-free labels for Notes and Folders.
///
/// Contract (do not change signatures without coordination):
/// - `Future<bool> existsFolderNameLower(int vaultId, String lower);`
/// - `Future<bool> existsNoteNameLower(int vaultId, int folderId, String lower);`
/// - `Future<String> generateUniqueNoteName(int vaultId, int folderId, String baseLabel);`
/// 노트/폴더 이름의 유일성 검사 및 자동 생성 유틸리티.
///
/// - 소문자 기반 유니크 제약을 준수하도록 도와줍니다.
/// - 충돌 시 " (n)" 접미사를 붙여 가용한 이름을 생성합니다.
class NameUtils {
  const NameUtils._();

  /// Returns true if a Folder exists in the vault with the given lower-cased name.
  static Future<bool> existsFolderNameLower(int vaultId, String lower) async {
    final isar = await IsarDb.instance.open();
    final normalized = lower.toLowerCase();

    // Use filter chain for compatibility across codegen variants.
    final Folder? found = await isar.folders
        .filter()
        .nameLowerForVaultUniqueEqualTo(normalized)
        .vaultIdEqualTo(vaultId)
        .findFirst();
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

    final NoteModel? found = await isar.noteModels
        .filter()
        .titleEqualTo(normalized, caseSensitive: false)
        .vaultIdEqualTo(vaultId)
        .folderIdEqualTo(scopedFolderId)
        .findFirst();
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
    final existsBase = await existsNoteNameLower(vaultId, folderId, baseLower);
    if (!existsBase) {
      return trimmed;
    }

    // Try with numeric suffixes starting from 2.
    for (int n = 2; n < 100000; n++) {
      final candidate = '$trimmed ($n)';
      final candidateLower = candidate.toLowerCase();
      final exists = await existsNoteNameLower(
        vaultId,
        folderId,
        candidateLower,
      );
      if (!exists) {
        return candidate;
      }
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

/// 볼트 내 소문자 폴더명 존재 여부를 반환합니다.
Future<bool> existsFolderNameLower(int vaultId, String lower) {
  return NameUtils.existsFolderNameLower(vaultId, lower);
}

/// (vaultId, folderId) 스코프에서 소문자 노트명 존재 여부를 반환합니다.
Future<bool> existsNoteNameLower(int vaultId, int folderId, String lower) {
  return NameUtils.existsNoteNameLower(vaultId, folderId, lower);
}

/// (vaultId, folderId) 스코프에서 유일한 노트 이름을 생성합니다.
Future<String> generateUniqueNoteName(
  int vaultId,
  int folderId,
  String baseLabel,
) {
  return NameUtils.generateUniqueNoteName(vaultId, folderId, baseLabel);
}