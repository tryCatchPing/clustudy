/// Vault 브라우저에서 사용하는 통합 아이템 표현.
///
/// 폴더와 노트를 하나의 리스트로 다루기 위한 경량 타입입니다.
enum VaultItemType { folder, note }

class VaultItem {
  /// 아이템 타입(폴더/노트)
  final VaultItemType type;

  /// 소속 Vault ID
  final String vaultId;

  /// 아이템 고유 식별자 (폴더면 folderId, 노트면 noteId)
  final String id;

  /// 표시 이름
  final String name;

  /// 정렬/표시를 위한 메타
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaultItem({
    required this.type,
    required this.vaultId,
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
}
