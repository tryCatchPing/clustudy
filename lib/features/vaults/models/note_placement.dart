/// 노트의 배치(트리) 정보를 제공하는 경량 모델.
///
/// - 콘텐츠(페이지/스케치 등)는 포함하지 않습니다.
/// - 표시/검증/연동(예: cross-vault 링크 차단)에 활용합니다.
const Object _unset = Object();

class NotePlacement {
  final String noteId;
  final String vaultId;
  final String? parentFolderId;
  final String name; // 표시명(케이스 보존)
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotePlacement({
    required this.noteId,
    required this.vaultId,
    required this.parentFolderId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  NotePlacement copyWith({
    String? noteId,
    String? vaultId,
    Object? parentFolderId = _unset,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotePlacement(
      noteId: noteId ?? this.noteId,
      vaultId: vaultId ?? this.vaultId,
      parentFolderId: identical(parentFolderId, _unset)
          ? this.parentFolderId
          : parentFolderId as String?,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
