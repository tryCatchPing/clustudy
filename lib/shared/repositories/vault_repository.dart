import '../../features/vaults/models/folder_model.dart';
import '../../features/vaults/models/vault_item.dart';
import '../../features/vaults/models/vault_model.dart';

/// Vault/Folder/Note 트리 관리에 대한 추상화.
///
/// 콘텐츠(페이지) 관리는 NotesRepository가 담당하고,
/// 계층(브라우저/이동/이름변경/삭제)은 VaultRepository가 담당합니다.
abstract class VaultRepository {
  //////////////////////////////////////////////////////////////////////////////
  // Vault
  //////////////////////////////////////////////////////////////////////////////

  /// 전체 Vault 목록을 관찰합니다.
  Stream<List<VaultModel>> watchVaults();

  /// 단일 Vault 조회.
  Future<VaultModel?> getVault(String vaultId);

  /// Vault 생성/이름변경/삭제
  Future<VaultModel> createVault(String name);
  Future<void> renameVault(String vaultId, String newName);
  Future<void> deleteVault(String vaultId);

  //////////////////////////////////////////////////////////////////////////////
  // Folder
  //////////////////////////////////////////////////////////////////////////////

  /// 특정 폴더의 하위 아이템(폴더+노트)을 관찰합니다. parentFolderId가 null이면 루트.
  Stream<List<VaultItem>> watchFolderChildren(
    String vaultId, {
    String? parentFolderId,
  });

  /// 폴더 생성/이름변경/이동/삭제
  Future<FolderModel> createFolder(
    String vaultId, {
    String? parentFolderId,
    required String name,
  });
  Future<void> renameFolder(String folderId, String newName);
  Future<void> moveFolder({
    required String folderId,
    String? newParentFolderId,
  });
  Future<void> deleteFolder(String folderId);

  //////////////////////////////////////////////////////////////////////////////
  // Note (트리 관점)
  //////////////////////////////////////////////////////////////////////////////

  /// 노트를 현재 폴더에 생성(콘텐츠는 NotesRepository에서 별도 생성/업서트).
  /// 반환: 생성된 noteId
  Future<String> createNote(
    String vaultId, {
    String? parentFolderId,
    required String name,
  });

  /// 노트 이름 변경(표시명/파일명 정책 반영).
  Future<void> renameNote(String noteId, String newName);

  /// 노트 이동(동일 Vault 내에서만 허용).
  Future<void> moveNote({
    required String noteId,
    String? newParentFolderId,
  });

  /// 노트 삭제(콘텐츠/파일/링크 정리는 상위 서비스에서 오케스트레이션).
  Future<void> deleteNote(String noteId);

  //////////////////////////////////////////////////////////////////////////////
  // Utilities
  //////////////////////////////////////////////////////////////////////////////

  /// 리소스 정리용.
  void dispose() {}
}
