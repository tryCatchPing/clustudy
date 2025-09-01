import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../../shared/services/pdf_export_service.dart';
import '../models/note_model.dart';

/// PDF 내보내기 모달 다이얼로그
///
/// 사용자가 PDF 내보내기 옵션을 선택하고 진행상황을 확인할 수 있는 UI를 제공합니다.
class PdfExportModal extends StatefulWidget {
  const PdfExportModal({
    super.key,
    required this.note,
    required this.pageNotifiers,
    this.initialCurrentPageIndex = 0,
  });

  /// 내보낼 노트
  final NoteModel note;

  /// 페이지별 ScribbleNotifier 맵
  final Map<String, ScribbleNotifier> pageNotifiers;

  /// 현재 페이지 인덱스 (현재 페이지 내보내기 기본값용)
  final int initialCurrentPageIndex;

  /// 모달을 표시합니다.
  static Future<void> show(
    BuildContext context, {
    required NoteModel note,
    required Map<String, ScribbleNotifier> pageNotifiers,
    int currentPageIndex = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 내보내기 중에는 닫기 방지
      builder: (context) => PdfExportModal(
        note: note,
        pageNotifiers: pageNotifiers,
        initialCurrentPageIndex: currentPageIndex,
      ),
    );
  }

  @override
  State<PdfExportModal> createState() => _PdfExportModalState();
}

class _PdfExportModalState extends State<PdfExportModal> {
  // 내보내기 설정
  ExportQuality _selectedQuality = ExportQuality.high;
  ExportRangeType _selectedRangeType = ExportRangeType.all;
  int _rangeStart = 1;
  int _rangeEnd = 1;

  // 진행상태
  bool _isExporting = false;
  double _progress = 0.0;
  String _progressMessage = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rangeEnd = widget.note.pages.length;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red),
          const SizedBox(width: 8),
          const Text('PDF 내보내기'),
          const Spacer(),
          if (!_isExporting)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isExporting) ...[
              _buildQualitySection(),
              const SizedBox(height: 16),
              _buildPageRangeSection(),
              const SizedBox(height: 16),
              _buildSummarySection(),
            ] else ...[
              _buildProgressSection(),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorSection(),
            ],
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '화질 설정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...ExportQuality.values.map((quality) {
          return RadioListTile<ExportQuality>(
            value: quality,
            groupValue: _selectedQuality,
            onChanged: _isExporting
                ? null
                : (value) {
                    setState(() {
                      _selectedQuality = value!;
                    });
                  },
            title: Text(quality.displayName),
            subtitle: Text(
              quality.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            dense: true,
          );
        }),
      ],
    );
  }

  Widget _buildPageRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '페이지 범위',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // 전체 페이지
        RadioListTile<ExportRangeType>(
          value: ExportRangeType.all,
          groupValue: _selectedRangeType,
          onChanged: _isExporting
              ? null
              : (value) {
                  setState(() {
                    _selectedRangeType = value!;
                  });
                },
          title: Text('전체 페이지 (${widget.note.pages.length}페이지)'),
          dense: true,
        ),

        // 현재 페이지
        RadioListTile<ExportRangeType>(
          value: ExportRangeType.current,
          groupValue: _selectedRangeType,
          onChanged: _isExporting
              ? null
              : (value) {
                  setState(() {
                    _selectedRangeType = value!;
                  });
                },
          title: Text('현재 페이지 (${widget.initialCurrentPageIndex + 1}페이지)'),
          dense: true,
        ),

        // 범위 지정
        RadioListTile<ExportRangeType>(
          value: ExportRangeType.range,
          groupValue: _selectedRangeType,
          onChanged: _isExporting
              ? null
              : (value) {
                  setState(() {
                    _selectedRangeType = value!;
                  });
                },
          title: const Text('범위 지정'),
          dense: true,
        ),

        // 범위 입력 필드
        if (_selectedRangeType == ExportRangeType.range)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: _rangeStart.toString(),
                    enabled: !_isExporting,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '시작',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) {
                      final num = int.tryParse(value);
                      if (num != null &&
                          num >= 1 &&
                          num <= widget.note.pages.length) {
                        setState(() {
                          _rangeStart = num;
                          if (_rangeStart > _rangeEnd) {
                            _rangeEnd = _rangeStart;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('~'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: _rangeEnd.toString(),
                    enabled: !_isExporting,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '끝',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) {
                      final num = int.tryParse(value);
                      if (num != null &&
                          num >= _rangeStart &&
                          num <= widget.note.pages.length) {
                        setState(() {
                          _rangeEnd = num;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(총 ${widget.note.pages.length}페이지)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final pageCount = _getSelectedPageCount();
    final estimatedSize = _getEstimatedFileSize(pageCount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내보내기 요약',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('페이지 수: $pageCount페이지'),
          Text('화질: ${_selectedQuality.displayName}'),
          Text('예상 크기: ${estimatedSize}MB'),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 16),
        Text(
          _progressMessage,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${(_progress * 100).toInt()}% 완료',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_isExporting) {
      return [
        TextButton(
          onPressed: () {
            // TODO: 내보내기 취소 기능 구현
          },
          child: const Text('취소'),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _startExport,
          icon: const Icon(Icons.download),
          label: const Text('내보내기'),
        ),
      ];
    }
  }

  int _getSelectedPageCount() {
    switch (_selectedRangeType) {
      case ExportRangeType.all:
        return widget.note.pages.length;
      case ExportRangeType.current:
        return 1;
      case ExportRangeType.range:
        return _rangeEnd - _rangeStart + 1;
    }
  }

  String _getEstimatedFileSize(int pageCount) {
    // 화질과 페이지 수에 따른 대략적인 파일 크기 추정
    const baseSizePerPage = {
      ExportQuality.standard: 0.8, // MB per page
      ExportQuality.high: 1.5,
      ExportQuality.ultra: 3.0,
    };

    final estimatedMB = pageCount * baseSizePerPage[_selectedQuality]!;
    return estimatedMB.toStringAsFixed(1);
  }

  ExportPageRange _buildPageRange() {
    switch (_selectedRangeType) {
      case ExportRangeType.all:
        return const ExportPageRange.all();
      case ExportRangeType.current:
        return ExportPageRange.current(widget.initialCurrentPageIndex);
      case ExportRangeType.range:
        return ExportPageRange.range(_rangeStart, _rangeEnd);
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _progressMessage = 'PDF 내보내기 준비 중...';
      _errorMessage = null;
    });

    try {
      final options = PdfExportOptions(
        quality: _selectedQuality,
        pageRange: _buildPageRange(),
        autoShare: true,
        shareText: '${widget.note.title} 노트를 공유합니다.',
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _progressMessage = message;
            });
          }
        },
      );

      final result = await PdfExportService.exportAndShare(
        widget.note,
        widget.pageNotifiers,
        options: options,
      );

      if (mounted) {
        if (result.success) {
          // 성공 시 모달 닫기
          Navigator.of(context).pop();

          // 성공 스낵바 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF 내보내기 완료! '
                '(${result.pageCount}페이지, ${(result.fileSize! / 1024 / 1024).toStringAsFixed(1)}MB)',
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '다시 공유',
                onPressed: () async {
                  if (result.filePath != null) {
                    await PdfExportService.sharePdf(result.filePath!);
                  }
                },
              ),
            ),
          );
        } else {
          setState(() {
            _isExporting = false;
            _errorMessage = result.error ?? '알 수 없는 오류가 발생했습니다.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = '내보내기 중 오류가 발생했습니다: $e';
        });
      }
    }
  }
}
