import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/organisms/creation_sheet.dart';
import '../../../components/atoms/app_textfield.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_icons.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';

Future<void> showDesignFolderCreationSheet(BuildContext context) {
  return showCreationSheet(context, const _DesignFolderCreationSheet());
}

class _DesignFolderCreationSheet extends StatefulWidget {
  const _DesignFolderCreationSheet();

  @override
  State<_DesignFolderCreationSheet> createState() => _DesignFolderCreationSheetState();
}

class _DesignFolderCreationSheetState extends State<_DesignFolderCreationSheet> {
  final _controller = TextEditingController(text: '새로운 폴더 이름');
  bool _busy = false;

  bool get _canSubmit => !_busy && _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${_controller.text.trim()}" 폴더 생성')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreationBaseSheet(
      title: '폴더 생성',
      onBack: () => Navigator.of(context).pop(),
      rightText: _busy ? '생성중...' : '생성',
      onRightTap: _canSubmit ? _submit : null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppIcons.folder,
              width: 200,
              height: 184,
              colorFilter: const ColorFilter.mode(AppColors.background, BlendMode.srcIn),
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: 280,
              child: AppTextField(
                controller: _controller,
                textAlign: TextAlign.center,
                autofocus: true,
                style: AppTextFieldStyle.none,
                textStyle: AppTypography.body2.copyWith(
                  color: AppColors.white,
                  height: 1.0,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
