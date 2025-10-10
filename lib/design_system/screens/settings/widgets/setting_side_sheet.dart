// lib/features/settings/widgets/settings_side_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../tokens/app_colors.dart';
import '../../../tokens/app_icons.dart';
import '../../../tokens/app_typography.dart';

/// 설정 시트 열기 (NoteLinks와 동일한 애니메이션/레이아웃)
Future<void> showSettingsSideSheet(
  BuildContext context, {
  // --- 상태/표시값 ---
  required bool pressureSensitivityEnabled, // 필압 여부
  required String appVersionText, // 예) "v1.0.0 (100)"
  required bool styleStrokesOnlyEnabled, // 스타일러스 입력만 허용 여부
  // --- 액션 콜백 (호스트에서 구현) ---
  required ValueChanged<bool> onToggleStyleStrokesOnly, // 스타일러스 입력만 허용 여부 변경
  required ValueChanged<bool> onTogglePressureSensitivity,
  required VoidCallback onShowLicenses, // 사용한 패키지(라이선스)
  required VoidCallback onOpenPrivacyPolicy, // 개인정보 보호
  required VoidCallback onOpenContact, // 연락처
  required VoidCallback onOpenGithubIssues, // 깃허브 이슈
  required VoidCallback onOpenTerms, // 이용 약관 및 조건
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.gray50.withOpacity(0.25),
    barrierLabel: 'settings',
    pageBuilder: (_, __, ___) {
      return _SettingsSideSheet(
        pressureSensitivityEnabled: pressureSensitivityEnabled,
        appVersionText: appVersionText,
        onTogglePressureSensitivity: onTogglePressureSensitivity,
        onShowLicenses: onShowLicenses,
        onOpenPrivacyPolicy: onOpenPrivacyPolicy,
        onOpenContact: onOpenContact,
        onOpenGithubIssues: onOpenGithubIssues,
        onOpenTerms: onOpenTerms,
        onToggleStyleStrokesOnly: onToggleStyleStrokesOnly,
        styleStrokesOnlyEnabled: styleStrokesOnlyEnabled,
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, anim, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _SettingsSideSheet extends StatelessWidget {
  const _SettingsSideSheet({
    required this.pressureSensitivityEnabled,
    required this.appVersionText,
    required this.onTogglePressureSensitivity,
    required this.onShowLicenses,
    required this.onOpenPrivacyPolicy,
    required this.onOpenContact,
    required this.onOpenGithubIssues,
    required this.onOpenTerms,
    required this.onToggleStyleStrokesOnly,
    required this.styleStrokesOnlyEnabled,
  });

  final bool pressureSensitivityEnabled;
  final String appVersionText;

  final ValueChanged<bool> onTogglePressureSensitivity;
  final VoidCallback onShowLicenses;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onOpenContact;
  final VoidCallback onOpenGithubIssues;
  final VoidCallback onOpenTerms;
  final ValueChanged<bool> onToggleStyleStrokesOnly;
  final bool styleStrokesOnlyEnabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          height: MediaQuery.of(context).size.height,
          margin: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.settings, // 없으면 AppIcons.link처럼 다른 아이콘 사용
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.gray40,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x11000000)),
              // Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _Section(
                      title: '환경 설정',
                      children: [
                        _SettingsTile.switchTile(
                          title: '필압 여부',
                          subtitle: '스타일러스/터치 입력 시 필압을 적용합니다.',
                          value: pressureSensitivityEnabled,
                          onChanged: onTogglePressureSensitivity,
                        ),
                        _SettingsTile.switchTile(
                          title: '스타일러스 입력만 허용',
                          subtitle: '스타일러스 입력만 허용합니다.',
                          value: styleStrokesOnlyEnabled,
                          onChanged: onToggleStyleStrokesOnly,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: '지원',
                      children: [
                        _SettingsTile.navTile(
                          title: '사용한 패키지',
                          subtitle: '오픈소스 라이선스 보기',
                          onTap: onShowLicenses,
                        ),
                        _SettingsTile.navTile(
                          title: '문제 생기는 경우 깃허브 이슈로',
                          subtitle: '버그/요청 사항을 이슈로 등록하세요',
                          onTap: onOpenGithubIssues,
                        ),
                        _SettingsTile.navTile(
                          title: '연락처',
                          subtitle: '문의 메일/채널로 연결합니다',
                          onTap: onOpenContact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: '법적 고지',
                      children: [
                        _SettingsTile.navTile(
                          title: '개인정보 보호',
                          onTap: onOpenPrivacyPolicy,
                        ),
                        _SettingsTile.navTile(
                          title: '이용 약관 및 조건',
                          onTap: onOpenTerms,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: '정보',
                      children: [
                        _SettingsTile.readonlyTile(
                          title: '버전',
                          trailingText: appVersionText, // 예: v1.0.0 (100)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: AppTypography.body2.copyWith(color: AppColors.gray40),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile._({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.readonly = false,
  });

  factory _SettingsTile.navTile({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return _SettingsTile._(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.gray30,
        size: 20,
      ),
    );
  }

  factory _SettingsTile.switchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _SettingsTile._(
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  factory _SettingsTile.readonlyTile({
    required String title,
    String? subtitle,
    required String trailingText,
  }) {
    return _SettingsTile._(
      title: title,
      subtitle: subtitle,
      readonly: true,
      trailing: Text(
        trailingText,
        style: AppTypography.body5.copyWith(color: AppColors.gray40),
      ),
    );
  }

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool readonly;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body5,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray40,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    if (readonly) return tile;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: tile,
    );
  }
}
