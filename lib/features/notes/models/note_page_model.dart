import 'dart:convert';

import 'package:it_contest/features/canvas/constants/note_editor_constant.dart';
import 'package:it_contest/features/canvas/models/link_model.dart'; // Import LinkModel
import 'package:scribble/scribble.dart';

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
class NotePageModel {
  /// 노트의 고유 ID.
  final String noteId;

  /// 페이지의 고유 ID.
  final String pageId;

  /// 페이지 번호 (1부터 시작).
  final int pageNumber;

  /// 스케치 데이터가 포함된 JSON 문자열.
  String jsonData;

  /// 페이지 배경의 타입.
  final PageBackgroundType backgroundType;

  /// PDF 배경 파일 경로 (앱 내부 저장).
  final String? backgroundPdfPath;

  /// PDF의 몇 번째 페이지인지.
  final int? backgroundPdfPageNumber;

  /// 원본 PDF 페이지 너비.
  final double? backgroundWidth;

  /// 원본 PDF 페이지 높이.
  final double? backgroundHeight;

  /// 사전 렌더링된 이미지 경로 (앱 내부 저장).
  final String? preRenderedImagePath;

  /// 배경 이미지 표시 여부 (필기만 보기 모드 지원).
  bool showBackgroundImage;

  /// 페이지에 포함된 링크 목록.
  final List<LinkModel> links;

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
  /// [links]는 페이지에 포함된 링크 목록입니다 (기본값: 빈 리스트).
  NotePageModel({
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
    this.links = const [], // Initialize with an empty list
  });

  /// JSON 데이터에서 [Sketch] 객체로 변환합니다.
  Sketch toSketch() => Sketch.fromJson(jsonDecode(jsonData));

  /// [Sketch] 객체에서 JSON 데이터로 업데이트합니다.
  ///
  /// [sketch]는 업데이트할 스케치 객체입니다.
  void updateFromSketch(Sketch sketch) {
    jsonData = jsonEncode(sketch.toJson());
  }

  /// PDF 배경이 있는지 여부를 반환합니다.
  bool get hasPdfBackground => backgroundType == PageBackgroundType.pdf && showBackgroundImage;

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
    String? jsonData,
    PageBackgroundType? backgroundType,
    String? backgroundPdfPath,
    int? backgroundPdfPageNumber,
    double? backgroundWidth,
    double? backgroundHeight,
    String? preRenderedImagePath,
    bool? showBackgroundImage,
    List<LinkModel>? links,
  }) {
    return NotePageModel(
      noteId: noteId,
      pageId: pageId,
      pageNumber: pageNumber,
      jsonData: jsonData ?? this.jsonData,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundPdfPath: backgroundPdfPath ?? this.backgroundPdfPath,
      backgroundPdfPageNumber: backgroundPdfPageNumber ?? this.backgroundPdfPageNumber,
      backgroundWidth: backgroundWidth ?? this.backgroundWidth,
      backgroundHeight: backgroundHeight ?? this.backgroundHeight,
      preRenderedImagePath: preRenderedImagePath ?? this.preRenderedImagePath,
      showBackgroundImage: showBackgroundImage ?? this.showBackgroundImage,
      links: links ?? this.links,
    );
  }
}
