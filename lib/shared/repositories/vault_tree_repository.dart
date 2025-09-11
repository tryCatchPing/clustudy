import '../../features/vaults/models/folder_model.dart';
import '../../features/vaults/models/vault_item.dart';
import '../../features/vaults/models/vault_model.dart';

/// VaultTreeRepository: Vault/Folder/Note "배치(placement) 트리" 전용 추상화.
///
/// 책임(포함)
/// - Vault/Folder의 생성·이름변경·이동·삭제
/// - 노트의 "위치와 표시명" 관리(배치 등록/이동/이름변경/삭제)
/// - 특정 폴더의 하위 항목(폴더+노트) 조회/관찰 및 정렬 정책(폴더 → 노트, 이름 ASC)
/// - 이름 정규화/중복 검사(동일 부모 폴더 내, 케이스 비구분)
/// - 이동 제약(동일 Vault 내, 폴더 사이클 방지)
///
/// 비책임(제외)
/// - 노트의 "콘텐츠(페이지/스케치/PDF 메타)" CRUD — NotesRepository에서 담당
/// - 링크 영속/스트림, 파일 시스템 정리 — 별도 Repository/Service에서 담당
/// - 유스케이스 단위 트랜잭션/롤백 — 상위 오케스트레이션 서비스에서 담당
///
/// 주의
/// - 본 인터페이스의 Note 관련 메서드는 "배치(placement)"만 다룹니다. 콘텐츠 생성/삭제는 호출자가
///   별도로 NotesRepository를 통해 처리해야 합니다.
abstract class VaultTreeRepository {
  //////////////////////////////////////////////////////////////////////////////
  // Vault
  //////////////////////////////////////////////////////////////////////////////

  /// 전체 Vault 목록을 관찰합니다.
  Stream<List<VaultModel>> watchVaults();

  /// 단일 Vault 조회.
  Future<VaultModel?> getVault(String vaultId);

  /// Vault 생성
  Future<VaultModel> createVault(String name);

  /// Vault 이름 변경
  Future<void> renameVault(String vaultId, String newName);

  /// Vault 삭제
  Future<void> deleteVault(String vaultId);

  //////////////////////////////////////////////////////////////////////////////
  // Folder
  //////////////////////////////////////////////////////////////////////////////

  /// 특정 폴더의 하위 아이템(폴더+노트)을 관찰합니다. parentFolderId가 null이면 루트.
  Stream<List<VaultItem>> watchFolderChildren(
    String vaultId, {
    String? parentFolderId,
  });

  /// 폴더 생성
  Future<FolderModel> createFolder(
    String vaultId, {
    String? parentFolderId,
    required String name,
  });

  /// 폴더 이름 변경
  Future<void> renameFolder(String folderId, String newName);

  /// 폴더 이동
  Future<void> moveFolder({
    required String folderId,
    String? newParentFolderId,
  });

  /// 폴더 삭제
  /// 주의: 이 삭제는 "배치 트리"에 대한 캐스케이드만 수행합니다.
  /// 하위 노트의 콘텐츠 및 링크 정리는 상위 오케스트레이션 서비스가 책임집니다.
  Future<void> deleteFolder(String folderId);

  //////////////////////////////////////////////////////////////////////////////
  // Note (트리/배치 관점)
  //////////////////////////////////////////////////////////////////////////////

  /// 노트의 "배치"를 현재 폴더에 등록합니다(콘텐츠는 NotesRepository에서 별도 생성/업서트).
  /// 반환: 생성된 noteId
  Future<String> createNote(
    String vaultId, {
    String? parentFolderId,
    required String name,
  });

  /// 노트 표시명(트리 상의 이름) 변경.
  Future<void> renameNote(String noteId, String newName);

  /// 노트 이동(동일 Vault 내에서만 허용).
  Future<void> moveNote({
    required String noteId,
    String? newParentFolderId,
  });

  /// 노트 배치 삭제(콘텐츠/파일/링크 정리는 상위 서비스에서 오케스트레이션).
  Future<void> deleteNote(String noteId);

  //////////////////////////////////////////////////////////////////////////////
  // Utilities
  //////////////////////////////////////////////////////////////////////////////

  /// 리소스 정리용.
  void dispose() {}
}
