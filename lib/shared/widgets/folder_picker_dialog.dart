import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/components/atoms/app_button.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_typography.dart';
import '../services/vault_notes_service.dart';

/// 라디오 항목에서 루트를 표현하기 위한 내부 식별자(반환 시 null로 변환)
const String _kRootId = '__ROOT__'; // 유지: 루트 전달 안전성 확보를 위한 내부 구현 디테일

/// 폴더 선택 다이얼로그
/// 반환: 선택한 folderId (루트 선택 시 null)
class FolderPickerDialog extends ConsumerStatefulWidget {
  const FolderPickerDialog({
    required this.vaultId,
    this.initialFolderId,
    this.disabledFolderSubtreeRootId,
    super.key,
  });

  final String vaultId;
  final String? initialFolderId;
  final String? disabledFolderSubtreeRootId;

  static Future<String?> show(
    BuildContext context, {
    required String vaultId,
    String? initialFolderId,
    String? disabledFolderSubtreeRootId,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (context) => Dialog(
        child: FolderPickerDialog(
          vaultId: vaultId,
          initialFolderId: initialFolderId,
          disabledFolderSubtreeRootId: disabledFolderSubtreeRootId,
        ),
      ),
    );
  }

  @override
  ConsumerState<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends ConsumerState<FolderPickerDialog> {
  bool _loading = true;
  List<_FolderRow> _rows = const <_FolderRow>[];
  Set<String> _disabled = const <String>{};
  String _selected = _kRootId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(vaultNotesServiceProvider);
    final rows = <_FolderRow>[];
    // Root option
    rows.add(const _FolderRow(id: _kRootId, name: '루트', path: ''));

    final folders = await svc.listFoldersWithPath(widget.vaultId);
    for (final f in folders) {
      rows.add(_FolderRow(id: f.folderId, name: f.name, path: f.pathLabel));
    }

    // Disabled subtree (for folder move)
    final disabled = <String>{};
    if (widget.disabledFolderSubtreeRootId != null) {
      disabled.addAll(
        await svc.listFolderSubtreeIds(
          widget.vaultId,
          widget.disabledFolderSubtreeRootId!,
        ),
      );
    }

    setState(() {
      _rows = rows;
      _disabled = disabled;
      _selected = widget.initialFolderId ?? _kRootId;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      style: AppButtonStyle.primary,
                      size: AppButtonSize.md,
                      borderRadius: 8,
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(
                              _selected == _kRootId ? null : _selected,
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x11000000)),
              // 리스트
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final r = _rows[index];
                          final disabled = _disabled.contains(r.id);
                          final isSelected = r.id == _selected;
                          return _FolderListItem(
                            name: r.name,
                            path: r.path,
                            isSelected: isSelected,
                            disabled: disabled,
                            onTap: disabled
                                ? null
                                : () => setState(() => _selected = r.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderRow {
  final String id;
  final String name;
  final String path;
  const _FolderRow({required this.id, required this.name, required this.path});
}

/// 폴더 리스트 아이템 (design_system 스타일 적용)
class _FolderListItem extends StatelessWidget {
  const _FolderListItem({
    required this.name,
    required this.path,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final String name;
  final String path;
  final bool isSelected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 색상 규칙: 선택 = gray30, 일반 = gray50, 비활성 = gray50 with opacity
    final Color textColor = disabled
        ? AppColors.gray50.withOpacity(0.45)
        : (isSelected ? AppColors.penBlue : AppColors.gray50);

    final Color iconTint = textColor;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            // 아이콘
            SvgPicture.asset(
              AppIcons.folder,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(iconTint, BlendMode.srcIn),
            ),
            const SizedBox(width: 8), // 아이콘–텍스트 간격 8px
            // 폴더명 + 경로
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(color: textColor),
                  ),
                  if (path.isNotEmpty)
                    Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
