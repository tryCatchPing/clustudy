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

/// 개인정보 보호 정책 텍스트
const String dummyPrivacyPolicyText = '''
개인정보 보호 정책

최종 수정일: 2025년 10월 12일

Clustudy("앱", "우리", "저희")는 사용자의 개인정보 보호를 매우 중요하게 생각합니다. 본 개인정보 보호 정책은 Clustudy가 사용자의 정보를 어떻게 수집, 사용, 보호하는지에 대해 설명합니다.

1. 수집하는 정보

본 앱은 다음과 같은 정보를 수집합니다:

• 사용자가 생성한 노트 및 필기 데이터
• 사용자가 업로드한 PDF 파일 및 이미지
• 노트 간 링크 관계 데이터
• 앱 설정 정보 (필압 설정, 스타일러스 입력 설정 등)

본 앱은 다음과 같은 정보를 수집하지 않습니다:

• 개인 식별 정보 (이름, 이메일, 전화번호)
• 위치 정보
• 사용 패턴 분석 데이터
• 광고 추적 정보

2. 정보의 사용 목적

수집된 정보는 다음과 같은 목적으로만 사용됩니다:

• 노트 필기 및 관리 기능 제공
• 사용자가 설정한 환경 설정 유지
• 앱 기능 개선 및 오류 수정

3. 정보의 저장 위치

중요: 모든 데이터는 사용자의 기기 내부(로컬 스토리지)에만 저장됩니다.

• 본 앱은 외부 서버를 운영하지 않습니다
• 데이터는 인터넷을 통해 전송되지 않습니다
• 클라우드 동기화 기능이 없습니다
• 모든 처리는 오프라인에서 이루어집니다

4. 정보의 공유

본 앱은 사용자의 정보를 제3자와 절대 공유하지 않습니다.

예외 사항:
• 법적 요구가 있는 경우 (법원 명령 등)
• 사용자의 명시적 동의가 있는 경우

5. 정보의 보안

• 모든 데이터는 기기의 내부 저장소에 보관됩니다
• iOS/Android의 샌드박스 보안 정책에 따라 보호됩니다
• 다른 앱은 Clustudy의 데이터에 접근할 수 없습니다

6. 사용자의 권리

사용자는 다음과 같은 권리를 가집니다:

• 언제든지 노트 및 데이터 삭제 가능
• 앱 삭제 시 모든 데이터 완전 제거
• 데이터 내보내기 (Share 기능 이용)

7. 아동의 개인정보

본 앱은 13세 미만 아동의 개인정보를 의도적으로 수집하지 않습니다. 13세 미만 아동이 본 앱을 사용하는 경우, 부모 또는 보호자의 동의가 필요합니다.

8. 개인정보 보호 정책의 변경

본 정책은 필요에 따라 변경될 수 있으며, 변경 시 앱 내에서 공지됩니다. 중대한 변경 사항이 있는 경우, 별도로 알림을 제공합니다.

9. 연락처

개인정보 보호와 관련한 문의사항이 있으시면 아래로 연락해주세요:

이메일: taeung.contact@gmail.com
GitHub 이슈: https://github.com/tryCatchPing/it-contest/issues

개발자: tryCatch태웅핑
''';

/// 이용 약관 및 조건 텍스트
const String dummyTermsOfServiceText = '''
이용 약관 및 조건

최종 수정일: 2025년 10월 12일

본 이용약관("약관")은 Clustudy("앱") 사용에 관한 조건을 규정합니다. 앱을 다운로드하거나 사용함으로써 본 약관에 동의하는 것으로 간주됩니다.

1. 서비스의 범위

Clustudy는 다음과 같은 기능을 제공합니다:

• 무한 캔버스 기반 노트 필기
• PDF 파일 가져오기 및 주석 달기
• 노트 간 양방향 링크 연결
• 그래프 뷰를 통한 노트 관계 시각화
• 노트 검색 및 관리

2. 라이선스

본 앱은 제한적이고 비독점적이며 양도 불가능한 라이선스를 부여합니다:

• 개인적, 비상업적 용도로만 사용 가능
• 앱을 수정, 배포, 판매할 수 없습니다
• 앱의 소스 코드를 역공학할 수 없습니다

예외: 오픈소스 컴포넌트는 각각의 라이선스를 따릅니다 (설정 > 사용한 패키지 참고)

3. 사용자의 책임

사용자는 다음 사항에 동의합니다:

• 앱을 합법적인 목적으로만 사용
• 타인의 권리를 침해하지 않음
• 앱의 정상적인 운영을 방해하지 않음
• 악성 코드나 유해 콘텐츠를 업로드하지 않음

4. 지적재산권

본 앱의 모든 콘텐츠, 디자인, 기능, 소스 코드는 저작권법에 의해 보호됩니다.

• 앱의 저작권: tryCatchPing
• 사용자가 생성한 노트의 저작권: 사용자 본인에게 귀속

5. 콘텐츠 책임

사용자는 본인이 생성한 모든 콘텐츠에 대해 책임을 집니다:

• 저작권 침해 콘텐츠 업로드 금지
• 불법적이거나 유해한 콘텐츠 작성 금지
• 콘텐츠 백업은 사용자의 책임

6. 면책 조항

본 앱은 "있는 그대로(AS IS)" 제공됩니다:

• 특정 목적에의 적합성을 보증하지 않습니다
• 오류가 없음을 보증하지 않습니다
• 데이터 손실에 대해 책임지지 않습니다
• 사용자는 정기적으로 데이터를 백업해야 합니다

7. 책임의 제한

법이 허용하는 최대 범위 내에서:

• 직접적, 간접적, 우발적 손해에 대해 책임지지 않습니다
• 데이터 손실, 이익 손실, 사업 중단 등에 대해 책임지지 않습니다
• 총 책임 한도: 사용자가 앱에 지불한 금액 (무료 앱의 경우 ₩0)

8. 서비스의 변경 및 중단

개발자는 다음 권리를 보유합니다:

• 사전 통지 없이 서비스를 변경하거나 중단할 수 있습니다
• 기능을 추가하거나 제거할 수 있습니다
• 앱 업데이트를 제공할 의무가 없습니다

9. 약관의 변경

본 약관은 필요에 따라 변경될 수 있으며:

• 변경 시 앱 내에서 공지됩니다
• 중대한 변경 사항은 별도 알림을 제공합니다
• 변경 후 앱을 계속 사용하면 동의한 것으로 간주됩니다

10. 분쟁 해결

본 약관과 관련한 분쟁은:

• 대한민국 법률에 따라 해석되고 적용됩니다
• 관할 법원: 서울중앙지방법원 또는 사용자 주소지 관할 법원

11. 연락처

약관과 관련한 문의사항이 있으시면 아래로 연락해주세요:

이메일: taeung.contact@gmail.com
GitHub 이슈: https://github.com/tryCatchPing/it-contest/issues

개발자: tryCatch태웅핑
''';
