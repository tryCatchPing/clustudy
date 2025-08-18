/// PDF 전처리 결과를 담는 데이터 클래스
///
/// PDF 선택 및 사전 렌더링 과정에서 생성되는 메타데이터를 보관합니다.
class PdfProcessedData {
  /// 노트 고유 ID
  final String noteId;

  /// 내부 복사된 PDF 파일 경로
  final String internalPdfPath;

  /// PDF에서 추출한 제목
  final String extractedTitle;

  /// 총 페이지 수
  final int totalPages;

  /// 각 페이지의 메타데이터
  final List<PdfPageData> pages;

  /// 전처리된 PDF의 메타데이터 집합을 생성합니다.
  ///
  /// - [noteId]: 노트 고유 ID
  /// - [internalPdfPath]: 내부 복사된 PDF 파일 경로
  /// - [extractedTitle]: PDF에서 추출한 제목
  /// - [totalPages]: 총 페이지 수
  /// - [pages]: 각 페이지의 메타데이터 목록
  const PdfProcessedData({
    required this.noteId,
    required this.internalPdfPath,
    required this.extractedTitle,
    required this.totalPages,
    required this.pages,
  });
}

/// 개별 PDF 페이지 데이터
///
/// 각 페이지의 정규화된 크기와 사전 렌더링된 이미지 경로를 포함합니다.
class PdfPageData {
  /// 페이지 번호 (1부터 시작)
  final int pageNumber;

  /// 페이지 너비
  final double width;

  /// 페이지 높이
  final double height;

  /// 사전 렌더링된 이미지 경로 (선택사항)
  final String? preRenderedImagePath;

  /// 개별 PDF 페이지의 메타데이터를 생성합니다.
  ///
  /// - [pageNumber]: 페이지 번호(1부터 시작)
  /// - [width]: 페이지 너비
  /// - [height]: 페이지 높이
  /// - [preRenderedImagePath]: 사전 렌더링된 이미지 경로(선택사항)
  const PdfPageData({
    required this.pageNumber,
    required this.width,
    required this.height,
    this.preRenderedImagePath,
  });
}
