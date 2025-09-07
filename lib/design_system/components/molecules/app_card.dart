import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart'; // intl 패키지 import
import '../atoms/app_textfield.dart';
import 'dart:typed_data'; // Uint8List 사용

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/tokens/app_shadows.dart';

class AppCard extends StatefulWidget {
  final String? svgIconPath;
  final Uint8List? previewImage;
  final String title;
  final DateTime date; // subtitle을 DateTime 타입의 date로 변경
  final VoidCallback? onTap;
  final ValueChanged<String>? onTitleChanged; // 제목 변경 시 호출될 콜백

  const AppCard({
    super.key,
    this.svgIconPath,
    this.previewImage,
    required this.title,
    required this.date,
    this.onTap,
    this.onTitleChanged,
  }) : assert(svgIconPath != null || previewImage != null, 'svgIconPath 또는 previewImage 둘 중 하나는 반드시 필요합니다.');

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
        baseOffset: 0, extentOffset: _textController.text.length,
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
    final formattedDate = DateFormat('yyyy.MM.dd').format(widget.date);

    // 미리보기(노트) 또는 폴더 아이콘
    final preview = widget.previewImage != null
        ? Container(
            decoration: BoxDecoration(
              boxShadow: AppShadows.small,
              borderRadius: BorderRadius.circular(AppSpacing.small),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.small),
              child: Image.memory(
                widget.previewImage!,
                width: 88,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          )
        : SvgPicture.asset(
            widget.svgIconPath!,
            width: 144,
            height: 136,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          );

    // 본문
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        preview,
        const SizedBox(height: AppSpacing.medium), // 아이콘 ↔ 이름 16px

        // 이름(보기/편집) — 항상 중앙 정렬, 1줄/ellipsis
        if (_isEditing)
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) _commitAndExit();
            },
            child: AppTextField(
              controller: _textController,
              style: AppTextFieldStyle.none,
              textStyle: AppTypography.body1.copyWith(color: AppColors.gray50),
              textAlign: TextAlign.center,     // ← 중앙 정렬
              autofocus: true,                 // ← 포커스
              focusNode: _focus,               // ← 포커스 제어
              onSubmitted: _commitAndExit,
              onChanged: (_) => setState(() {}), // 확인 버튼 활성화 등 필요 시
            ),
          )
        else
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.body1.copyWith(color: AppColors.gray50),
          ),

        const SizedBox(height: AppSpacing.small), // 이름 ↔ 날짜 8px
        Text(
          formattedDate,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.body5.copyWith(color: AppColors.gray30),
        ),
      ],
    );

    // 전체 16px 패딩 + InkWell로 접근성/리플
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isEditing ? null : widget.onTap,
        onLongPress: _isEditing ? null : _enterEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium), // ← 16px 패딩
          child: body,
        ),
      ),
    );
  }
}
