// lib/features/common/dialogs/move_destination_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../components/atoms/app_button.dart';

/// 트리 데이터 모델
class MoveNode {
  final String id;
  final String title;
  final bool isVault; // true: vault, false: folder
  final bool disabled; // '임시 vault' 등 비활성화
  final List<MoveNode> children;
  MoveNode({
    required this.id,
    required this.title,
    required this.isVault,
    this.disabled = false,
    this.children = const [],
  });
}

/// 다이얼로그 열기
Future<String?> showMoveDestinationDialog(
  BuildContext context, {
  required List<MoveNode> roots, // vault 리스트(각 vault 아래 folder 트리)
  String? selectedId, // 현재 선택된 목적지
  required VoidCallback onMoveTap, // '이동' 버튼 탭 시(선택 유지용이면 비워도 OK)
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: Colors.black.withOpacity(0.25),
    pageBuilder: (_, __, ___) {
      return SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
              child: _MovePanel(
                roots: roots,
                initialSelectedId: selectedId,
                onMoveTap: onMoveTap,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// 내부 패널
class _MovePanel extends StatefulWidget {
  const _MovePanel({
    required this.roots,
    required this.initialSelectedId,
    required this.onMoveTap,
  });

  final List<MoveNode> roots;
  final String? initialSelectedId;
  final VoidCallback onMoveTap;

  @override
  State<_MovePanel> createState() => _MovePanelState();
}

class _MovePanelState extends State<_MovePanel> {
  late String? _selectedId = widget.initialSelectedId;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 헤더
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.gray50,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    text: '이동',
                    style: AppButtonStyle.primary, // primary 컬러
                    size: AppButtonSize.md, // 필요시 sm/lg 조정
                    borderRadius: 8, // (이전 모양 유지 원하면)
                    onPressed: _selectedId == null
                        ? null
                        : () {
                            widget.onMoveTap();
                            Navigator.of(context).pop(_selectedId);
                          },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x11000000)),
            // 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.roots.length,
                itemBuilder: (_, i) => _VaultSection(
                  node: widget.roots[i],
                  selectedId: _selectedId,
                  onSelect: (id) => setState(() => _selectedId = id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// vault 섹션 + 하위 폴더들
class _VaultSection extends StatefulWidget {
  const _VaultSection({
    required this.node,
    required this.selectedId,
    required this.onSelect,
  });
  final MoveNode node;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  State<_VaultSection> createState() => _VaultSectionState();
}

class _VaultSectionState extends State<_VaultSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final vault = widget.node;

    return Column(
      children: [
        _FolderRow(
          id: vault.id,
          title: vault.title,
          isVault: true,
          disabled: vault.disabled,
          selectedId: widget.selectedId,
          onTap: vault.disabled ? null : () => widget.onSelect(vault.id),
          showChevron: true,
          onChevronTap: () => setState(() => _expanded = !_expanded),
          expanded: _expanded,
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                for (final child in vault.children)
                  _FolderTreeRow(
                    node: child,
                    selectedId: widget.selectedId,
                    onSelect: widget.onSelect,
                    depth: 0,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0x11000000)),
      ],
    );
  }
}

/// 재귀 폴더 렌더러
class _FolderTreeRow extends StatefulWidget {
  const _FolderTreeRow({
    required this.node,
    required this.selectedId,
    required this.onSelect,
    required this.depth,
  });
  final MoveNode node;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final int depth;

  @override
  State<_FolderTreeRow> createState() => _FolderTreeRowState();
}

class _FolderTreeRowState extends State<_FolderTreeRow> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final hasChildren = n.children.isNotEmpty;

    return Column(
      children: [
        _FolderRow(
          id: n.id,
          title: n.title,
          isVault: n.isVault,
          disabled: n.disabled,
          selectedId: widget.selectedId,
          indent: 24.0 * (widget.depth + 1),
          onTap: n.disabled ? null : () => widget.onSelect(n.id),
          showChevron: hasChildren,
          onChevronTap: hasChildren
              ? () => setState(() => _expanded = !_expanded)
              : null,
          expanded: _expanded,
        ),
        if (_expanded)
          for (final c in n.children)
            _FolderTreeRow(
              node: c,
              selectedId: widget.selectedId,
              onSelect: widget.onSelect,
              depth: widget.depth + 1,
            ),
      ],
    );
  }
}

/// 단일 행(요구사항 반영: 아이콘–텍스트 간격 8px, 폰트 body2, 색상 규칙)
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.id,
    required this.title,
    required this.isVault,
    required this.disabled,
    required this.selectedId,
    this.indent = 0,
    this.onTap,
    this.showChevron = false,
    this.onChevronTap,
    this.expanded,
  });

  final String id;
  final String title;
  final bool isVault;
  final bool disabled;
  final String? selectedId;
  final double indent;
  final VoidCallback? onTap;
  final bool showChevron;
  final VoidCallback? onChevronTap;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = id == selectedId;

    // 색상 규칙: 현재 위치/선택 = gray30, 그 외 = gray50, 비활성은 투명도
    final Color textColor = disabled
        ? AppColors.gray50.withOpacity(0.45)
        : (isSelected ? AppColors.gray30 : AppColors.gray50);

    final Color iconTint = textColor;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: EdgeInsets.only(left: 16 + indent, right: 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            // 아이콘
            SvgPicture.asset(
              isVault ? AppIcons.folderVault : AppIcons.folder,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(iconTint, BlendMode.srcIn),
            ),
            const SizedBox(width: 8), // 아이콘–텍스트 간격 8px (요구사항)
            // 폴더명
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body2.copyWith(color: textColor),
              ),
            ),
            if (showChevron)
              IconButton(
              onPressed: onChevronTap,
              padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                splashRadius: 18,
                icon: _ChevronIcon(expanded: expanded ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChevronIcon extends StatelessWidget {
  const _ChevronIcon({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    // 회전 가능한 환경: AnimatedRotation 사용
    return AnimatedRotation(
      turns: expanded ? 0.25 : 0.0, // 0.25 turn = 90도
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: SvgPicture.asset(
        AppIcons.chevronRight,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(AppColors.gray50, BlendMode.srcIn),
        // 만약 어떤 플랫폼에서 회전 이슈가 있으면 아래의 onPictureError로 다운 폴백
        // ignore: deprecated_member_use
        // onPictureError: (_, __) => SvgPicture.asset(AppIcons.chevronDown, ...),
      ),
    );
  }
}
