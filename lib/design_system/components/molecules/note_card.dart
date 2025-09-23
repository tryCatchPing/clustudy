import 'package:flutter/material.dart';

import 'app_card.dart';

/// 노트/폴더를 표시하는 카드 위젯
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.date,
    required this.onTap,
    this.onLongPressStart,
  });

  final String iconPath;
  final String title;
  final DateTime date;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails details)? onLongPressStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      svgIconPath: iconPath,
      title: title,
      date: date,
      onTap: onTap,
      onLongPressStart: onLongPressStart,
    );
  }
}
