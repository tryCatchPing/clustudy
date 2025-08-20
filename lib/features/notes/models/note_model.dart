import 'package:isar/isar.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';

part 'note_model.g.dart';

/// 노트의 출처 타입을 정의합니다.
@embedded
enum NoteSourceType {
  /// 빈 노트.
  blank,

  /// PDF 기반 노트.
  pdfBased,
}

/// 노트 모델입니다.
///
/// 노트의 고유 ID, 제목, 페이지 목록, 출처 타입 및 PDF 관련 메타데이터를 포함합니다.
@collection
class NoteModel {
  /// 노트의 데이터베이스 ID.
  Id id = Isar.autoIncrement;

  /// 노트의 고유 ID.
  @Index(unique: true)
  late String noteId;

  /// 노트의 제목.
  @Index(caseSensitive: false)
  late String title;

  /// 소프트 삭제를 위한 삭제 시간.
  @Index()
  DateTime? deletedAt;

  /// 노트의 출처 타입 (빈 노트 또는 PDF 기반).
  @enumerated
  late NoteSourceType sourceType;

  /// 원본 PDF 파일의 경로 (PDF 기반 노트인 경우에만 해당).
  String? sourcePdfPath;

  /// 원본 PDF의 총 페이지 수 (PDF 기반 노트인 경우에만 해당).
  int? totalPdfPages;

  /// 노트가 생성된 날짜 및 시간.
  @Index()
  late DateTime createdAt;

  /// 노트가 마지막으로 업데이트된 날짜 및 시간.
  @Index()
  late DateTime updatedAt;

  /// [NoteModel]의 기본 생성자.
  NoteModel();

  /// PDF 기반 노트인지 여부를 반환합니다.
  bool get isPdfBased => sourceType == NoteSourceType.pdfBased;

  /// 빈 노트인지 여부를 반환합니다.
  bool get isBlank => sourceType == NoteSourceType.blank;

  /// 새 값으로 일부 필드를 교체한 복제본을 반환합니다.
  NoteModel copyWith({
    String? noteId,
    String? title,
    NoteSourceType? sourceType,
    String? sourcePdfPath,
    int? totalPdfPages,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    final copy = NoteModel();
    copy.id = id;
    copy.noteId = noteId ?? this.noteId;
    copy.title = title ?? this.title;
    copy.sourceType = sourceType ?? this.sourceType;
    copy.sourcePdfPath = sourcePdfPath ?? this.sourcePdfPath;
    copy.totalPdfPages = totalPdfPages ?? this.totalPdfPages;
    copy.createdAt = createdAt ?? this.createdAt;
    copy.updatedAt = updatedAt ?? this.updatedAt;
    copy.deletedAt = deletedAt ?? this.deletedAt;
    return copy;
  }
}
