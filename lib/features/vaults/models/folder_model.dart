/// Folder 모델.
///
/// Vault 내 계층 구조를 구성합니다. 루트의 경우 `parentFolderId`가 null 입니다.
class FolderModel {
  /// 고유 식별자(UUID)
  final String folderId;

  /// 소속 Vault ID
  final String vaultId;

  /// 표시 이름
  final String name;

  /// 부모 폴더 ID (루트면 null)
  final String? parentFolderId;

  /// 생성/수정 시각
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderModel({
    required this.folderId,
    required this.vaultId,
    required this.name,
    this.parentFolderId,
    required this.createdAt,
    required this.updatedAt,
  });

  FolderModel copyWith({
    String? folderId,
    String? vaultId,
    String? name,
    String? parentFolderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderModel(
      folderId: folderId ?? this.folderId,
      vaultId: vaultId ?? this.vaultId,
      name: name ?? this.name,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
