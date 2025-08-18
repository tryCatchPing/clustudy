// ignore_for_file: public_member_api_docs

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

/// PDF 기반 썸네일을 생성하고 파일 경로를 반환하는 서비스.
///
/// 싱글턴 인스턴스 [`ThumbnailService.instance`] 를 통해 사용합니다.
class ThumbnailService {
  ThumbnailService._();
  static final ThumbnailService instance = ThumbnailService._();

  /// PDF 페이지를 렌더링(또는 이미 렌더링된 경우 재사용)하여
  /// 썸네일 파일의 절대 경로를 반환합니다.
  ///
  /// - [noteId]: 노트(문서) 식별자
  /// - [pageIndex]: 0 기반 페이지 인덱스
  /// - [dpi]: 렌더링 해상도(DPI). 기본값은 144
  ///
  /// 반환값: 생성(또는 존재)한 썸네일 이미지 파일의 절대 경로
  ///
  /// 오류: 파일이 존재하지 않으면 [StateError]를 던집니다.
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
