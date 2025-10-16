// lib/features/notes/widgets/note_links_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_typography.dart';

class NoteLinkItem {
  final String title; // 예: '새 노트 2025-09-19 1643 - p.1'
  final String? subtitle; // 예: 'From note' / 'Page 1' 등
  final VoidCallback onTap; // 탭 시 이동
  NoteLinkItem({required this.title, this.subtitle, required this.onTap});
}

Future<void> showNoteLinksSheet(
  BuildContext context, {
  required List<NoteLinkItem> outgoing,
  required List<NoteLinkItem> backlinks,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.25),
    barrierLabel: 'links',
    pageBuilder: (_, __, ___) {
      return NoteLinksSideSheet(outgoing: outgoing, backlinks: backlinks);
    },
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, anim, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0), // 오른쪽에서
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class NoteLinksSideSheet extends StatelessWidget {
  const NoteLinksSideSheet({
    super.key,
    required this.outgoing,
    required this.backlinks,
  });
  final List<NoteLinkItem> outgoing;
  final List<NoteLinkItem> backlinks;

  @override
  Widget build(BuildContext context) {
    // 화면 우측에 너비 360 고정
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
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.link,        
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Links',
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
              // 목록
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _Section(
                      title: 'Outgoing (this page)',
                      items: outgoing,
                      emptyText: 'Outgoing links not found.',
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Backlinks (to this note)',
                      items: backlinks,
                      emptyText: 'Backlinks not found.',
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
  const _Section({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<NoteLinkItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 타이틀
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: AppTypography.body2.copyWith(color: AppColors.gray40),
              ),
            ],
          ),
        ),
        // 내용
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              emptyText,
              style: AppTypography.body4.copyWith(color: AppColors.gray30),
            ),
          )
        else
          ...items.map((e) => _LinkTile(item: e)),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.item});
  final NoteLinkItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).maybePop();
        item.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: AppTypography.body5,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                item.subtitle!,
                style: AppTypography.caption.copyWith(color: AppColors.gray40),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
