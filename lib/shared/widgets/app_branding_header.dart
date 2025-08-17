import 'package:flutter/material.dart';

/// 🏷️ 앱 브랜딩 헤더 위젯
///
/// 앱의 로고, 제목, 부제목을 표시하는 재사용 가능한 위젯입니다.
/// 홈페이지, 소개 페이지, 온보딩 등에서 사용할 수 있습니다.
class AppBrandingHeader extends StatelessWidget {
  /// 헤더의 제목.
  final String title;

  /// 헤더의 부제목.
  final String subtitle;

  /// 헤더에 표시될 아이콘.
  final IconData? icon;

  /// 아이콘의 색상.
  final Color? iconColor;

  /// 헤더의 배경 색상.
  final Color? backgroundColor;

  /// [AppBrandingHeader]의 생성자.
  ///
  /// [title]은 헤더의 제목입니다 (기본값: '손글씨 노트 앱').
  /// [subtitle]은 헤더의 부제목입니다 (기본값: '4인 팀 프로젝트 - Flutter 데모').
  /// [icon]은 헤더에 표시될 아이콘입니다 (기본값: [Icons.edit_note]).
  /// [iconColor]는 아이콘의 색상입니다 (기본값: [Color(0xFF6750A4)]).
  /// [backgroundColor]는 헤더의 배경 색상입니다 (기본값: [Colors.white]).
  const AppBrandingHeader({
    super.key,
    this.title = '손글씨 노트 앱',
    this.subtitle = '4인 팀 프로젝트 - Flutter 데모',
    this.icon = Icons.edit_note,
    this.iconColor = const Color(0xFF6750A4),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (icon != null)
            Icon(
              icon!,
              size: 80,
              color: iconColor,
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
