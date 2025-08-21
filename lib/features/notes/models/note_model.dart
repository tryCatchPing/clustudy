import 'package:isar/isar.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';

part 'note_model.g.dart';

/// 노트의 출처 타입을 정의합니다.
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

  @Index()
  late int vaultId;

  @Index()
  late int folderId;

  @Index()
  late int sortIndex;

  /// 소프트 삭제를 위한 삭제 시간.
  @Index()
  DateTime? deletedAt;

  /// 노트에 포함된 페이지 목록 (임시로 일반 필드로 설정).
  @ignore
  List<NotePageModel>? _pages;

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

  /// [NoteModel]의 생성자.
  ///
  /// [noteId]는 노트의 고유 ID입니다.
  /// [title]은 노트의 제목입니다.
  /// [sourceType]은 노트의 출처 타입입니다 (기본값: [NoteSourceType.blank]).
  /// [sourcePdfPath]는 원본 PDF 파일의 경로입니다.
  /// [totalPdfPages]는 원본 PDF의 총 페이지 수입니다.
  /// [createdAt]은 노트가 생성된 날짜 및 시간입니다 (기본값: 현재 시간).
  /// [updatedAt]은 노트가 마지막으로 업데이트된 날짜 및 시간입니다 (기본값: 현재 시간).
  NoteModel.create({
    required String noteId,
    required String title,
    required this.vaultId,
    required this.folderId,
    this.sortIndex = 1000,
    NoteSourceType sourceType = NoteSourceType.blank,
    String? sourcePdfPath,
    int? totalPdfPages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : noteId = noteId,
       title = title,
       sourceType = sourceType,
       sourcePdfPath = sourcePdfPath,
       totalPdfPages = totalPdfPages,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// PDF 기반 노트인지 여부를 반환합니다.
  bool get isPdfBased => sourceType == NoteSourceType.pdfBased;

  /// 빈 노트인지 여부를 반환합니다.
  bool get isBlank => sourceType == NoteSourceType.blank;

  /// 새 값으로 일부 필드를 교체한 복제본을 반환합니다.
  NoteModel copyWith({
    String? noteId,
    String? title,
    int? vaultId,
    int? folderId,
    int? sortIndex,
    NoteSourceType? sourceType,
    String? sourcePdfPath,
    int? totalPdfPages,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<NotePageModel>? pages,
  }) {
    final copy = NoteModel();
    copy.id = id;
    copy.noteId = noteId ?? this.noteId;
    copy.title = title ?? this.title;
    copy.vaultId = vaultId ?? this.vaultId;
    copy.folderId = folderId ?? this.folderId;
    copy.sortIndex = sortIndex ?? this.sortIndex;
    copy.sourceType = sourceType ?? this.sourceType;
    copy.sourcePdfPath = sourcePdfPath ?? this.sourcePdfPath;
    copy.totalPdfPages = totalPdfPages ?? this.totalPdfPages;
    copy.createdAt = createdAt ?? this.createdAt;
    copy.updatedAt = updatedAt ?? this.updatedAt;
    copy.deletedAt = deletedAt ?? this.deletedAt;
    copy.pages = pages ?? this.pages;
    return copy;
  }

  /// pages 필드에 접근하기 위한 getter (기존 코드 호환성)
  @ignore
  List<NotePageModel> get pagesList => _pages ?? [];

  /// 기존 코드와의 호환성을 위한 pages getter
  @ignore
  List<NotePageModel> get pages => _pages ?? [];

  /// pages setter
  @ignore
  set pages(List<NotePageModel> pages) {
    _pages = pages;
  }
}
