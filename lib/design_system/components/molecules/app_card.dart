import 'dart:typed_data'; // Uint8List 사용

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart'; // intl 패키지 import

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_shadows.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../tokens/app_sizes.dart';
import '../atoms/app_textfield.dart';

class AppCard extends StatefulWidget {
  final String? svgIconPath;
  final Uint8List? previewImage;
  final String title;
  final DateTime date; // subtitle을 DateTime 타입의 date로 변경
  final VoidCallback? onTap;
  final ValueChanged<String>? onTitleChanged; // 제목 변경 시 호출될 콜백
  final void Function(LongPressStartDetails details)? onLongPressStart;

  const AppCard({
    super.key,
    this.svgIconPath,
    this.previewImage,
    required this.title,
    required this.date,
    this.onTap,
    this.onTitleChanged,
    this.onLongPressStart,
  }) : assert(
         svgIconPath != null || previewImage != null,
         'svgIconPath 또는 previewImage 둘 중 하나는 반드시 필요합니다.',
       );

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isEditing = false; // 수정 모드 여부를 관리하는 상태
  late TextEditingController _textController;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.title);
  }

  // 부모 위젯에서 title이 변경되었을 때 controller에도 반영
  @override
  void didUpdateWidget(covariant AppCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != oldWidget.title && !_isEditing) {
      _textController.text = widget.title;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _enterEdit() {
    setState(() => _isEditing = true);
    // 다음 프레임에 포커스 이동 + 전체 선택
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    });
  }

  void _commitAndExit([String? value]) {
    final newTitle = (value ?? _textController.text).trim();
    _focus.unfocus();
    setState(() => _isEditing = false);
    if (newTitle.isNotEmpty && newTitle != widget.title) {
      widget.onTitleChanged?.call(newTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.previewImage != null
        ? AppShadows.shadowizeVector(
            width: AppSizes.folderIconW,
            height: AppSizes.folderIconH,
            borderRadius: AppSpacing.small,
            child: Image.memory(widget.previewImage!, fit: BoxFit.cover),
            // y/sigma/color는 AppShadows 내부 기본값 그대로 써도 OK
          )
        : AppShadows.shadowizeVector(
            width: AppSizes.folderIconW,
            height: AppSizes.folderIconH,
            child: SvgPicture.asset(
              widget.svgIconPath!,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            y: 2,
            sigma: 4,
            color: const Color(0x40000000),
          );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _isEditing ? null : widget.onTap,
       onLongPressStart: _isEditing
        ? null
        : (d) => widget.onLongPressStart?.call(d),
        child: SizedBox(
          width: 144,
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // or EdgeInsets.zero
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // 아이콘 144×136 고정
                preview,
                const SizedBox(height: 16), // 아이콘↔이름
                // 이름 (16px, bold, line-height 1.0)
                if (_isEditing)
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) _commitAndExit();
                    },
                    child: AppTextField(
                      controller: _textController,
                      style: AppTextFieldStyle.none,
                      textStyle: AppTypography.body1.copyWith(
                        color: AppColors.gray50,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                      autofocus: true,
                      focusNode: _focus,
                      onSubmitted: _commitAndExit,
                    ),
                  )
                else
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.gray50,
                      height: 1.0, // ← 중요
                    ),
                  ),

                const SizedBox(height: 8), // 이름↔날짜
                // 날짜 (13px, line-height 1.0)
                Text(
                  DateFormat('yyyy.MM.dd').format(widget.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gray30,
                    height: 1.0, // ← 중요
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
