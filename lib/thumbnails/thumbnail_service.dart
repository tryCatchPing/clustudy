/// 썸네일 서비스 라이브러리
///
/// PDF 페이지의 사전 렌더링(캐시)을 보장하고 해당 이미지 경로를
/// 반환하는 간단한 API를 제공합니다. 향후에는 캔버스의 필기 레이어를
/// PDF 이미지 위에 합성하는 기능을 확장할 수 있습니다.
library thumbnail_service;
import 'dart:io';

import 'package:it_contest/shared/services/pdf_cache_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// `ThumbnailService` 는 PDF 페이지의 썸네일을 생성하고 관리하는 서비스를 제공합니다.
///
/// 이 서비스는 PDF 페이지를 사전 렌더링(캐시)하여 해당 이미지 파일의 경로를 반환하는
/// 간단한 API를 제공합니다. 향후에는 캔버스 필기 레이어를 PDF 이미지 위에 합성하는
/// 기능으로 확장될 수 있습니다.
///
/// 싱글턴 인스턴스 [`ThumbnailService.instance`] 를 통해 접근할 수 있습니다.
class ThumbnailService {
  /// `ThumbnailService` 의 private 생성자입니다.
  ThumbnailService._();
  /// `ThumbnailService` 의 싱글턴 인스턴스입니다.
  static final ThumbnailService instance = ThumbnailService._();

  /// 주어진 [noteId], [pageIndex], [dpi] 에 해당하는 PDF 페이지 썸네일을 생성하거나
  /// 이미 존재하는 경우 해당 썸네일을 재사용하여 썸네일 파일의 절대 경로를 반환합니다.
  ///
  /// 썸네일은 내부적으로 [PdfCacheService] 를 통해 렌더링되고 캐시됩니다.
  ///
  /// - Parameters:
  ///   - [noteId]: 썸네일을 생성할 노트(문서)의 고유 식별자입니다.
  ///   - [pageIndex]: 썸네일을 생성할 페이지의 0 기반 인덱스입니다.
  ///   - [dpi]: 썸네일 이미지의 렌더링 해상도(DPI)입니다. 기본값은 144입니다.
  ///
  /// - Returns: 생성되었거나 이미 존재하는 썸네일 이미지 파일의 절대 경로입니다.
  ///
  /// - Throws:
  ///   - [StateError]: 썸네일 생성이 실패했거나 파일이 존재하지 않는 경우 발생합니다.
  Future<String> generateThumbnail({
    required int noteId,
    required int pageIndex,
    int dpi = 144,
  }) async {
    await PdfCacheService.instance.renderAndCache(
      noteId: noteId,
      pageIndex: pageIndex,
      dpi: dpi,
    );
    final docs = await getApplicationDocumentsDirectory();
    final rel = PdfCacheService.instance.path(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
    final abs = p.join(docs.path, rel);
    if (!File(abs).existsSync()) {
      throw StateError('Thumbnail not created');
    }
    return abs;
  }
}
