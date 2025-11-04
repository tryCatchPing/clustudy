import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../errors/pdf_import_cancelled_exception.dart';

/// 📁 파일 선택 서비스 (모바일 앱 전용)
///
/// PDF 파일 선택 기능을 제공합니다.
/// 파일 경로 기반으로 작동합니다.
class FilePickerService {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  FilePickerService._();

  /// PDF 파일을 선택하고 파일 경로를 반환합니다.
  ///
  /// Returns:
  /// - String: 선택된 PDF 파일의 절대 경로
  /// - null: 선택 취소 또는 실패
  static Future<String?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false, // 앱에서는 파일 경로만 필요
      );

      if (result != null) {
        final file = result.files.single;

        if (file.path != null) {
          debugPrint('✅ PDF 파일 선택됨: ${file.path}');
          return file.path!;
        } else {
          debugPrint('❌ 파일 경로를 가져올 수 없습니다.');
          return null;
        }
      } else {
        debugPrint('ℹ️ PDF 파일 선택 취소됨.');
        throw const PdfImportCancelledException();
      }
    } catch (e) {
      debugPrint('❌ 파일 선택 중 오류 발생: $e');
      return null;
    }
  }
}
