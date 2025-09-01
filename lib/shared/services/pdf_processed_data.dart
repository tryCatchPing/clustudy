/// PDF 전처리 결과를 담는 데이터 클래스
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

  const PdfProcessedData({
    required this.noteId,
    required this.internalPdfPath,
    required this.extractedTitle,
    required this.totalPages,
    required this.pages,
  });
}

/// 개별 PDF 페이지 데이터
class PdfPageData {
  /// 페이지 번호 (1부터 시작)
  final int pageNumber;

  /// 페이지 너비
  final double width;

  /// 페이지 높이
  final double height;

  /// 사전 렌더링된 이미지 경로 (선택사항)
  final String? preRenderedImagePath;

  const PdfPageData({
    required this.pageNumber,
    required this.width,
    required this.height,
    this.preRenderedImagePath,
  });
}
