// lib/utils/pickers/pick_pdf.dart
import 'package:file_selector/file_selector.dart';

/// 시스템 파일 선택기(iOS Files/Android 문서 선택기)를 열어 PDF 1개 선택.
/// 사용자가 취소하면 null 반환.
Future<XFile?> pickPdf() {
  return openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
      ),
    ],
  );
}
