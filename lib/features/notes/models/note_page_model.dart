import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:it_contest/features/canvas/constants/note_editor_constant.dart';
import 'package:scribble/scribble.dart';

part 'note_page_model.g.dart';

/// 페이지 배경의 타입을 정의합니다.
enum PageBackgroundType {
  /// 빈 배경.
  blank,

  /// PDF 배경.
  pdf,
}

/// 노트 페이지 모델입니다.
///
/// 각 노트 페이지의 고유 ID, 페이지 번호, 스케치 데이터 및 배경 정보를 포함합니다.
@collection
class NotePageModel {
  /// 데이터베이스 ID.
  Id id = Isar.autoIncrement;

  /// 노트의 고유 ID.
  @Index()
  late String noteId;

  // NoteModel과의 관계는 noteId로만 관리

  /// 페이지의 고유 ID.
  @Index(unique: true)
  late String pageId;

  /// 페이지 번호 (1부터 시작).
  @Index()
  late int pageNumber;

  /// 스케치 데이터가 포함된 JSON 문자열.
  late String jsonData;

  /// 페이지 배경의 타입.
  @enumerated
  late PageBackgroundType backgroundType;

  /// PDF 배경 파일 경로 (앱 내부 저장).
  String? backgroundPdfPath;

  /// PDF의 몇 번째 페이지인지.
  int? backgroundPdfPageNumber;

  /// 원본 PDF 페이지 너비.
  double? backgroundWidth;

  /// 원본 PDF 페이지 높이.
  double? backgroundHeight;

  /// 사전 렌더링된 이미지 경로 (앱 내부 저장).
  String? preRenderedImagePath;

  /// 배경 이미지 표시 여부 (필기만 보기 모드 지원).
  late bool showBackgroundImage;

  /// 페이지에 그려진 링커 직사각형 목록 (JSON 문자열로 저장).
  late String linkerRectanglesJson;

  /// [NotePageModel]의 기본 생성자.
  NotePageModel();

  /// [NotePageModel]의 생성자.
  ///
  /// [noteId]는 노트의 고유 ID입니다.
  /// [pageId]는 페이지의 고유 ID입니다.
  /// [pageNumber]는 페이지 번호입니다.
  /// [jsonData]는 스케치 데이터가 포함된 JSON 문자열입니다.
  /// [backgroundType]은 페이지 배경의 타입입니다 (기본값: [PageBackgroundType.blank]).
  /// [backgroundPdfPath]는 PDF 배경 파일 경로입니다.
  /// [backgroundPdfPageNumber]는 PDF의 페이지 번호입니다.
  /// [backgroundWidth]는 원본 PDF 페이지 너비입니다.
  /// [backgroundHeight]는 원본 PDF 페이지 높이입니다.
  /// [preRenderedImagePath]는 사전 렌더링된 이미지 경로입니다.
  /// [showBackgroundImage]는 배경 이미지 표시 여부입니다 (기본값: true).
  /// [linkerRectangles]는 페이지에 그려진 링커 직사각형 목록입니다 (기본값: 빈 리스트).
  NotePageModel.create({
    required this.noteId,
    required this.pageId,
    required this.pageNumber,
    required this.jsonData,
    this.backgroundType = PageBackgroundType.blank,
    this.backgroundPdfPath,
    this.backgroundPdfPageNumber,
    this.backgroundWidth,
    this.backgroundHeight,
    this.preRenderedImagePath,
    this.showBackgroundImage = true,
    List<Rect> linkerRectangles = const [],
  }) : linkerRectanglesJson =
            jsonEncode(_linkerRectanglesToJson(linkerRectangles));

  /// 링커 직사각형 목록 getter (JSON에서 파싱).
  @ignore
  List<Rect> get linkerRectangles =>
      _linkerRectanglesFromJson(linkerRectanglesJson);

  /// 링커 직사각형 목록 setter (JSON으로 직렬화).
  set linkerRectangles(List<Rect> rectangles) {
    linkerRectanglesJson = jsonEncode(_linkerRectanglesToJson(rectangles));
  }

  /// JSON 데이터에서 [Sketch] 객체로 변환합니다.
  Sketch toSketch() => Sketch.fromJson(jsonDecode(jsonData));

  /// [Sketch] 객체에서 JSON 데이터로 업데이트합니다.
  ///
  /// [sketch]는 업데이트할 스케치 객체입니다.
  void updateFromSketch(Sketch sketch) {
    jsonData = jsonEncode(sketch.toJson());
  }

  /// 링커 직사각형을 추가합니다.
  void addLinkerRectangle(Rect rect) {
    final rectangles = linkerRectangles;
    linkerRectangles = [...rectangles, rect];
  }

  /// 링커 직사각형을 제거합니다.
  void removeLinkerRectangle(Rect rect) {
    final rectangles = linkerRectangles;
    linkerRectangles = rectangles.where((r) => r != rect).toList();
  }

  /// 링커 직사각형 목록을 업데이트합니다.
  void updateLinkerRectangles(List<Rect> rectangles) {
    linkerRectangles = [...rectangles];
  }

  /// 링커 직사각형을 JSON으로 직렬화합니다.
  static List<Map<String, dynamic>> _linkerRectanglesToJson(
    List<Rect> rectangles,
  ) {
    return rectangles
        .map((rect) => {
              'left': rect.left,
              'top': rect.top,
              'right': rect.right,
              'bottom': rect.bottom,
            })
        .toList();
  }

  /// JSON에서 링커 직사각형을 역직렬화합니다.
  static List<Rect> _linkerRectanglesFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final json = jsonDecode(jsonString) as List<dynamic>?;
    if (json == null) {
      return [];
    }
    return json
        .cast<Map<String, dynamic>>()
        .map((rectJson) => Rect.fromLTRB(
              (rectJson['left'] as num).toDouble(),
              (rectJson['top'] as num).toDouble(),
              (rectJson['right'] as num).toDouble(),
              (rectJson['bottom'] as num).toDouble(),
            ))
        .toList();
  }

  /// 확장된 JSON 데이터를 반환합니다 (Scribble + Linker 포함).
  String toExtendedJson() {
    final sketchJson = jsonDecode(jsonData) as Map<String, dynamic>;
    sketchJson['linkerRectangles'] = _linkerRectanglesToJson(linkerRectangles);
    return jsonEncode(sketchJson);
  }

  /// 확장된 JSON 데이터에서 업데이트합니다.
  void updateFromExtendedJson(String extendedJson) {
    final data = jsonDecode(extendedJson) as Map<String, dynamic>;
    final linkerData = data.remove('linkerRectangles');

    // Scribble 데이터 업데이트
    jsonData = jsonEncode(data);

    // 링커 데이터 업데이트
    if (linkerData != null) {
      linkerRectanglesJson = jsonEncode(linkerData);
    }
  }

  /// PDF 배경이 있는지 여부를 반환합니다.
  bool get hasPdfBackground =>
      backgroundType == PageBackgroundType.pdf && showBackgroundImage;

  /// 사전 렌더링된 이미지가 있는지 여부를 반환합니다.
  bool get hasPreRenderedImage => preRenderedImagePath != null;

  /// 실제 그리기 영역의 너비를 반환합니다.
  double get drawingAreaWidth {
    if (hasPdfBackground && backgroundWidth != null) {
      return backgroundWidth!;
    }
    return NoteEditorConstants.canvasWidth;
  }

  /// 실제 그리기 영역의 높이를 반환합니다.
  double get drawingAreaHeight {
    if (hasPdfBackground && backgroundHeight != null) {
      return backgroundHeight!;
    }
    return NoteEditorConstants.canvasHeight;
  }

  /// 새 값으로 일부 필드를 교체한 복제본을 반환합니다.
  NotePageModel copyWith({
    String? noteId,
    String? pageId,
    int? pageNumber,
    String? jsonData,
    PageBackgroundType? backgroundType,
    String? backgroundPdfPath,
    int? backgroundPdfPageNumber,
    double? backgroundWidth,
    double? backgroundHeight,
    String? preRenderedImagePath,
    bool? showBackgroundImage,
    List<Rect>? linkerRectangles,
  }) {
    final copy = NotePageModel();
    copy.id = id;
    copy.noteId = noteId ?? this.noteId;
    copy.pageId = pageId ?? this.pageId;
    copy.pageNumber = pageNumber ?? this.pageNumber;
    copy.jsonData = jsonData ?? this.jsonData;
    copy.backgroundType = backgroundType ?? this.backgroundType;
    copy.backgroundPdfPath = backgroundPdfPath ?? this.backgroundPdfPath;
    copy.backgroundPdfPageNumber =
        backgroundPdfPageNumber ?? this.backgroundPdfPageNumber;
    copy.backgroundWidth = backgroundWidth ?? this.backgroundWidth;
    copy.backgroundHeight = backgroundHeight ?? this.backgroundHeight;
    copy.preRenderedImagePath =
        preRenderedImagePath ?? this.preRenderedImagePath;
    copy.showBackgroundImage =
        showBackgroundImage ?? this.showBackgroundImage;
    if (linkerRectangles != null) {
      copy.linkerRectangles = linkerRectangles;
    } else {
      copy.linkerRectanglesJson = linkerRectanglesJson;
    }
    return copy;
  }
}
