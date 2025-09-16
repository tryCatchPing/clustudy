import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/components/atoms/app_textfield.dart';

class FolderCreationSheet extends StatefulWidget {
  const FolderCreationSheet({
    super.key,
    required this.onCreate, // (name) async
  });

  final Future<void> Function(String name) onCreate;

  @override
  State<FolderCreationSheet> createState() => _FolderCreationSheetState();
}

class _FolderCreationSheetState extends State<FolderCreationSheet> {
  final _c = TextEditingController(text: '새로운 폴더 이름');
  bool _busy = false;

  Future<void> _submit() async {
    final name = _c.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onCreate(name);
      if (!mounted) return;
      Navigator.of(context).pop(); // 성공 시 시트 닫기
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreationBaseSheet(
      title: '폴더 생성',
      onBack: () => Navigator.of(context).pop(),
      rightText: _busy ? '생성중...' : '생성',
      onRightTap: _submit,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppIcons.folder,
              width: 200, height: 184,
              colorFilter: const ColorFilter.mode(AppColors.background, BlendMode.srcIn),
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: 280,
              child: AppTextField(
                controller: _c,
                textAlign: TextAlign.center,
                autofocus: true,
                style: AppTextFieldStyle.none,
                textStyle: AppTypography.body2.copyWith(color: AppColors.white),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
