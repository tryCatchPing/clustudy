// lib/design_system/screens/settings/widgets/legal_text_dialog.dart
import 'package:flutter/material.dart';

import '../../../tokens/app_colors.dart';
import '../../../tokens/app_typography.dart';

/// 법적 문서(개인정보 보호 정책, 이용약관)를 앱 내에서 표시하는 다이얼로그
///
/// 사용 예시:
/// ```dart
/// showLegalTextDialog(
///   context: context,
///   title: '개인정보 보호 정책',
///   content: _privacyPolicyText, // 아래 더미 데이터 참고
/// );
/// ```
Future<void> showLegalTextDialog({
  required BuildContext context,
  required String title,
  required String content,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.gray50.withOpacity(0.25),
    builder: (context) => _LegalTextDialog(
      title: title,
      content: content,
    ),
  );
}

class _LegalTextDialog extends StatelessWidget {
  const _LegalTextDialog({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (setting_side_sheet 스타일 참고)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.gray40,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x11000000)),

            // Body - 스크롤 가능한 텍스트 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  content,
                  style: AppTypography.body5.copyWith(
                    color: AppColors.gray40,
                    height: 1.6, // 줄 간격
                  ),
                ),
              ),
            ),

            // Footer - 닫기 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '확인',
                    style: AppTypography.body2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 더미 데이터 - 실제 내용으로 교체하세요
// ============================================================================

/// [더미] 개인정보 보호 정책 텍스트
///
/// 🔧 편집 방법:
/// 1. 아래 텍스트를 실제 개인정보 보호 정책으로 교체하세요
/// 2. \n\n 으로 문단을 구분합니다
/// 3. Markdown은 지원하지 않으므로 일반 텍스트로 작성하세요
const String dummyPrivacyPolicyText = '''
개인정보 보호 정책

최종 수정일: 2025년 1월 1일

본 개인정보 보호 정책은 Clustudy(이하 "앱")이 사용자의 개인정보를 어떻게 수집, 사용, 보호하는지에 대해 설명합니다.

1. 수집하는 정보

본 앱은 다음과 같은 정보를 수집합니다:
- 사용자가 생성한 노트 및 필기 데이터
- 사용자가 업로드한 PDF 파일
- 앱 사용 통계 (오프라인)

2. 정보의 사용

수집된 정보는 다음과 같은 목적으로 사용됩니다:
- 노트 필기 기능 제공
- 사용자 경험 개선
- 기술적 문제 해결

3. 정보의 저장

모든 데이터는 사용자의 기기 내부에만 저장됩니다.
본 앱은 외부 서버로 데이터를 전송하지 않습니다.

4. 정보의 공유

본 앱은 사용자의 개인정보를 제3자와 공유하지 않습니다.

5. 사용자의 권리

사용자는 언제든지 앱을 삭제하여 모든 데이터를 제거할 수 있습니다.

6. 연락처

개인정보 보호와 관련한 문의사항이 있으시면 아래로 연락해주세요:
이메일: taeung.contact@gmail.com

7. 정책의 변경

본 정책은 필요에 따라 변경될 수 있으며, 변경 시 앱 내에서 공지됩니다.
''';

/// [더미] 이용약관 텍스트
///
/// 🔧 편집 방법:
/// 1. 아래 텍스트를 실제 이용약관으로 교체하세요
/// 2. \n\n 으로 문단을 구분합니다
/// 3. Markdown은 지원하지 않으므로 일반 텍스트로 작성하세요
const String dummyTermsOfServiceText = '''
이용 약관 및 조건

최종 수정일: 2025년 1월 1일

본 이용약관은 Clustudy(이하 "앱") 사용에 관한 조건을 규정합니다.

1. 서비스의 범위

본 앱은 다음과 같은 기능을 제공합니다:
- 무한 캔버스 기반 노트 필기
- PDF 파일 가져오기 및 주석
- 노트 간 링크 연결
- 그래프 뷰를 통한 노트 관계 시각화

2. 사용자의 책임

사용자는 다음 사항에 동의합니다:
- 앱을 합법적인 목적으로만 사용
- 타인의 권리를 침해하지 않음
- 앱의 정상적인 운영을 방해하지 않음

3. 지적재산권

본 앱의 모든 콘텐츠, 디자인, 소스 코드는 저작권법에 의해 보호됩니다.
사용자가 생성한 노트의 저작권은 사용자에게 있습니다.

4. 면책 조항

본 앱은 "있는 그대로" 제공됩니다.
데이터 손실이나 기타 손해에 대해 개발자는 책임지지 않습니다.
사용자는 정기적으로 데이터를 백업할 책임이 있습니다.

5. 서비스의 변경 및 중단

개발자는 사전 통지 없이 서비스를 변경하거나 중단할 수 있습니다.

6. 약관의 변경

본 약관은 필요에 따라 변경될 수 있으며, 변경 시 앱 내에서 공지됩니다.

7. 준거법

본 약관은 대한민국 법률에 따라 해석되고 적용됩니다.

8. 연락처

약관과 관련한 문의사항이 있으시면 아래로 연락해주세요:
이메일: taeung.contact@gmail.com
GitHub 이슈: https://github.com/tryCatchPing/it-contest/issues
''';
