import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

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

/// Bottom sheet that drives the Android-only PDF export MVP flow.
class PdfExportMvpSheet extends ConsumerStatefulWidget {
  /// Creates the PDF export MVP sheet.
  const PdfExportMvpSheet({
    super.key,
    required this.note,
    required this.pageNotifiers,
    required this.simulatePressure,
    required this.hostContext,
  });

  /// Note to export.
  final NoteModel note;

  /// Loaded page notifiers keyed by pageId.
  final Map<String, CustomScribbleNotifier> pageNotifiers;

  /// Whether pressure simulation should be applied during export.
  final bool simulatePressure;

  /// Context of the host screen.
  ///
  /// Used for surfacing snackbars after dismissing the sheet.
  final BuildContext hostContext;

  /// Presents the sheet with the provided dependencies.
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
    return PopScope(
      canPop: !_isExporting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isExporting) {
          Navigator.of(context).pop();
        }
      },
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
              const SizedBox(height: AppSpacing.large),
              Text(
                '화질',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                '고화질 (4x)',
                style: AppTypography.body3.copyWith(
                  color: AppColors.background.withValues(alpha: 0.75),
                ),
              ),

              const Spacer(),
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                const SizedBox(height: AppSpacing.medium),
              ],
              AppButton(
                text: 'PDF 공유하기',
                onPressed: _isExporting ? null : _startExport,
                loading: _isExporting,
                borderRadius: 16,
                fullWidth: true,
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
        ],
      ),
    );
  }

  Future<void> _startExport() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    PdfExportResult? result;
    try {
      result = await ref
          .read(pdfExportMvpServiceProvider)
          .exportToDownloads(
            note: widget.note,
            pageNotifiers: widget.pageNotifiers,
            simulatePressure: widget.simulatePressure,
          );

      final shareFiles = [
        XFile(
          result.filePath,
          mimeType: 'application/pdf',
          name: p.basename(result.filePath),
        ),
      ];
      await Share.shareXFiles(
        shareFiles,
        sharePositionOrigin: _shareOriginRect(),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (!widget.hostContext.mounted) {
        return;
      }
      AppSnackBar.show(
        widget.hostContext,
        AppErrorSpec.success(
          'PDF를 공유했어요.',
        ),
      );
    } on PdfExportException catch (error) {
      _handleError(error.message);
    } catch (error) {
      _handleError('예상치 못한 오류가 발생했습니다. $error');
    } finally {
      if (result != null) {
        unawaited(
          ref.read(pdfExportMvpServiceProvider).deleteTempFile(result.filePath),
        );
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isExporting = false;
      _errorMessage = message;
    });
  }

  void _handleCloseTapped() {
    if (_isExporting) {
      return;
    }
    Navigator.of(context).pop();
  }

  Rect? _shareOriginRect() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return null;
    }
    final origin = renderBox.localToGlobal(Offset.zero);
    return origin & renderBox.size;
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
