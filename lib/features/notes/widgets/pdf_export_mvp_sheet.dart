import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/atoms/app_button.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../shared/errors/app_error_spec.dart';
import '../../../shared/services/pdf_export_mvp_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../canvas/notifiers/custom_scribble_notifier.dart';
import '../models/note_model.dart';

class PdfExportMvpSheet extends ConsumerStatefulWidget {
  const PdfExportMvpSheet({
    super.key,
    required this.note,
    required this.pageNotifiers,
    required this.simulatePressure,
    required this.hostContext,
  });

  final NoteModel note;
  final Map<String, CustomScribbleNotifier> pageNotifiers;
  final bool simulatePressure;
  final BuildContext hostContext;

  static Future<void> show(
    BuildContext context, {
    required NoteModel note,
    required Map<String, CustomScribbleNotifier> pageNotifiers,
    required bool simulatePressure,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PdfExportMvpSheet(
        note: note,
        pageNotifiers: pageNotifiers,
        simulatePressure: simulatePressure,
        hostContext: context,
      ),
    );
  }

  @override
  ConsumerState<PdfExportMvpSheet> createState() => _PdfExportMvpSheetState();
}

class _PdfExportMvpSheetState extends ConsumerState<PdfExportMvpSheet> {
  bool _isExporting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isExporting,
      child: CreationBaseSheet(
        title: 'PDF 내보내기',
        onBack: _handleCloseTapped,
        rightText: _isExporting ? '진행 중' : '닫기',
        onRightTap: _isExporting ? null : () => Navigator.of(context).pop(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isExporting ? _buildProgressContent() : _buildReadyContent(),
        ),
      ),
    );
  }

  Widget _buildReadyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: AppSpacing.large),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '저장 위치',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Android · 다운로드 > Clustudy',
                style: AppTypography.body3.copyWith(
                  color: AppColors.background.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                '범위',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                '모든 페이지 (${widget.note.pages.length}p)',
                style: AppTypography.body3.copyWith(
                  color: AppColors.background.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                const SizedBox(height: AppSpacing.medium),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '내 기기에 저장',
                      onPressed: _isExporting ? null : _startExport,
                      loading: _isExporting,
                      borderRadius: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  const Expanded(
                    child: AppButton(
                      text: '공유 (준비 중)',
                      onPressed: null,
                      borderRadius: 16,
                      style: AppButtonStyle.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.large),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
        ),
        const SizedBox(height: AppSpacing.large),
        Text(
          '모든 페이지를 PDF로 저장하는 중이에요...\n화면을 닫지 말아 주세요.',
          textAlign: TextAlign.center,
          style: AppTypography.body3.copyWith(
            color: AppColors.background,
            height: 1.5,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.large),
          _ErrorBanner(message: _errorMessage!),
        ],
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.note.title,
            style: AppTypography.subtitle1.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray50,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            '총 ${widget.note.pages.length}개 페이지 / 고화질(4x)',
            style: AppTypography.body4.copyWith(
              color: AppColors.gray40,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startExport() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(pdfExportMvpServiceProvider)
          .exportToDownloads(
            note: widget.note,
            pageNotifiers: widget.pageNotifiers,
            simulatePressure: widget.simulatePressure,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackBar.show(
        widget.hostContext,
        AppErrorSpec.success(
          'PDF를 저장했어요.\n${result.filePath}',
        ),
      );
    } on PdfExportException catch (error) {
      _handleError(error.message);
    } catch (error) {
      _handleError('예상치 못한 오류가 발생했습니다. $error');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _isExporting = false;
      _errorMessage = message;
    });
  }

  void _handleCloseTapped() {
    if (_isExporting) return;
    Navigator.of(context).pop();
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body4.copyWith(
                color: Colors.red[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
