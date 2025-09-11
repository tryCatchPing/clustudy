/// Vault 모델.
///
/// 링크/그래프/검색/저장의 스코프 단위. 하나의 Vault 안에 Folder/Note/Link가 속합니다.
class VaultModel {
  /// 고유 식별자(UUID v4 권장)
  final String vaultId;

  /// 표시 이름(파일명 정책과 동일하게 취급될 수 있음)
  final String name;

  /// 생성/수정 시각
  final DateTime createdAt;
  final DateTime updatedAt;

  // isar 도입 시 isarLink 추가 고려

  const VaultModel({
    required this.vaultId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  VaultModel copyWith({
    String? vaultId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultModel(
      vaultId: vaultId ?? this.vaultId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
