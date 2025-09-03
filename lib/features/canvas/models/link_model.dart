/// 노트 페이지 내 특정 영역이 다른 노트/페이지로 연결되는 링크 모델입니다.
///
/// 소스는 항상 노트의 한 페이지이며, 대상은 노트 전체 또는 특정 페이지가 될 수 있습니다.
class LinkModel {
  /// 링크의 고유 ID(UUID v4 권장).
  final String id;

  /// 링크를 건 노트와 페이지 ID (소스).
  final String sourceNoteId;
  final String sourcePageId;

  /// 대상 타입 및 대상 식별자.
  final String targetNoteId;
  final String? targetPageId; // targetType == page 일 때 필수, 그 외 null

  /// 페이지 로컬 좌표계의 바운딩 박스.
  final double bboxLeft;
  final double bboxTop;
  final double bboxWidth;
  final double bboxHeight;

  /// 표시명(선택). 비어있으면 대상 제목으로 계산합니다.
  final String? label;

  /// 선택 영역의 키워드/문맥(선택).
  final String? anchorText;

  /// 생성/수정 시각.
  final DateTime createdAt;
  final DateTime updatedAt;

  const LinkModel({
    required this.id,
    required this.sourceNoteId,
    required this.sourcePageId,
    required this.targetNoteId,
    this.targetPageId,
    required this.bboxLeft,
    required this.bboxTop,
    required this.bboxWidth,
    required this.bboxHeight,
    this.label,
    this.anchorText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 바운딩 박스가 유효한 최소 크기인지 확인합니다.
  bool get isValidBbox => bboxWidth > 0 && bboxHeight > 0;

  LinkModel copyWith({
    String? id,
    String? sourceNoteId,
    String? sourcePageId,
    String? targetNoteId,
    String? targetPageId,
    double? bboxLeft,
    double? bboxTop,
    double? bboxWidth,
    double? bboxHeight,
    String? label,
    String? anchorText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkModel(
      id: id ?? this.id,
      sourceNoteId: sourceNoteId ?? this.sourceNoteId,
      sourcePageId: sourcePageId ?? this.sourcePageId,
      targetNoteId: targetNoteId ?? this.targetNoteId,
      targetPageId: targetPageId ?? this.targetPageId,
      bboxLeft: bboxLeft ?? this.bboxLeft,
      bboxTop: bboxTop ?? this.bboxTop,
      bboxWidth: bboxWidth ?? this.bboxWidth,
      bboxHeight: bboxHeight ?? this.bboxHeight,
      label: label ?? this.label,
      anchorText: anchorText ?? this.anchorText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'sourceNoteId': sourceNoteId,
    'sourcePageId': sourcePageId,
    'targetNoteId': targetNoteId,
    'targetPageId': targetPageId,
    'bboxLeft': bboxLeft,
    'bboxTop': bboxTop,
    'bboxWidth': bboxWidth,
    'bboxHeight': bboxHeight,
    'label': label,
    'anchorText': anchorText,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LinkModel.fromJson(Map<String, Object?> map) {
    return LinkModel(
      id: map['id'] as String,
      sourceNoteId: map['sourceNoteId'] as String,
      sourcePageId: map['sourcePageId'] as String,
      targetNoteId: map['targetNoteId'] as String,
      targetPageId: map['targetPageId'] as String?,
      bboxLeft: (map['bboxLeft'] as num).toDouble(),
      bboxTop: (map['bboxTop'] as num).toDouble(),
      bboxWidth: (map['bboxWidth'] as num).toDouble(),
      bboxHeight: (map['bboxHeight'] as num).toDouble(),
      label: map['label'] as String?,
      anchorText: map['anchorText'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'LinkModel(id: '
        '$id, source: $sourceNoteId/$sourcePageId, target: '
        '$targetNoteId/${targetPageId ?? '-'} '
        'bbox: ($bboxLeft,$bboxTop,$bboxWidth,$bboxHeight))';
  }
}
