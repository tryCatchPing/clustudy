// lib/design_system/components/atoms/app_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

enum AppTextFieldStyle { search, underline, none }

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final AppTextFieldStyle style;
  final TextStyle? textStyle; // 텍스트 스타일을 직접 받도록 수정
  final String? svgPrefixIconPath; // SVG 아이콘 경로
  final String? svgClearIconPath; // SVG 'x' 아이콘 경로

  const AppTextField({
    super.key,
    required this.controller,
    required this.style, // 스타일을 필수로 받도록 변경
    this.hintText,
    this.textStyle,
  }) : svgPrefixIconPath = null,
       svgClearIconPath = null;

  const AppTextField.search({
    super.key,
    required this.controller,
    this.hintText,
    this.svgPrefixIconPath,
    this.svgClearIconPath,
  }) : style = AppTextFieldStyle.search,
       textStyle = null; // search 스타일은 내부에서 정의

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    // search 스타일일 경우 입력 시 스타일, 아닐 경우 외부에서 받은 스타일 적용
    final inputTextStyle = widget.style == AppTextFieldStyle.search
        ? AppTypography.body3.copyWith(color: AppColors.gray50)
        : widget.textStyle;

    // TextField 위젯 생성
    final textField = TextField(
      controller: widget.controller,
      style: inputTextStyle,
      decoration: _buildDecoration(),
      textAlign: widget.style == AppTextFieldStyle.underline
          ? TextAlign.center
          : TextAlign.start, // underline일때 중앙 정렬
    );

    // underline 스타일일 경우에만 Container로 감싸서 너비 고정
    if (widget.style == AppTextFieldStyle.underline) {
      return SizedBox(
        width: 200, // 가로 200px 너비 고정
        child: textField,
      );
    }

    return textField; // 나머지 스타일은 전체 너비 사용
  }

  InputDecoration _buildDecoration() {
    switch (widget.style) {
      case AppTextFieldStyle.search:
        return InputDecoration(
          // 1. 배경색 추가
          filled: true,
          fillColor: AppColors.gray10,

          // 2. 내부 패딩(여백) 추가
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.medium, // 위아래 16px
            horizontal: AppSpacing.small, // 좌우 8px
          ),

          // --- 기존 코드 ---
          hintText: widget.hintText,
          hintStyle: AppTypography.body3.copyWith(color: AppColors.gray40),
          prefixIcon: widget.svgPrefixIconPath != null
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SvgPicture.asset(widget.svgPrefixIconPath!),
                )
              : null,
          suffixIcon:
              widget.controller.text.isNotEmpty &&
                  widget.svgClearIconPath != null
              ? IconButton(
                  icon: SvgPicture.asset(widget.svgClearIconPath!),
                  onPressed: () => widget.controller.clear(),
                )
              : null,

          // 3. 테두리 스타일 수정 (배경색이 있으므로 평소에는 테두리 숨김)
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.small),
            borderSide: BorderSide.none, // 평소에는 테두리 없음
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.small),
            borderSide: const BorderSide(
              // 포커스될 때만 Primary 색상 테두리 표시
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        );
      case AppTextFieldStyle.underline: // 생성용 스타일
        return InputDecoration(
          hintText: widget.hintText,
          hintStyle: widget.textStyle?.copyWith(color: AppColors.gray30),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.background, // Background 컬러
              width: 1.0, // 세로 1px
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.background, // 포커스 시에도 동일
              width: 1.5, // 살짝 두껍게
            ),
          ),
        );

      case AppTextFieldStyle.none: // 수정용 스타일
        return const InputDecoration(
          border: InputBorder.none, // 모든 테두리 제거
          focusedBorder: InputBorder.none, // 포커스 시에도 테두리 없음
          enabledBorder: InputBorder.none,
        );
    }
  }
}
