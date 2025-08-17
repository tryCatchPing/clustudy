import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_contest/features/notes/data/notes_repository_provider.dart';
import 'package:it_contest/shared/services/pdf_recovery_service.dart';

/// 재렌더링 진행 상황을 표시하는 모달
///
/// PDF 페이지들을 재렌더링하는 동안 실시간 진행률을 표시하고,
/// 사용자가 작업을 취소할 수 있는 옵션을 제공합니다.
class RecoveryProgressModal extends ConsumerStatefulWidget {
  /// [RecoveryProgressModal]의 생성자.
  ///
  /// [noteId]는 복구할 노트의 고유 ID입니다.
  /// [noteTitle]은 복구할 노트의 제목입니다.
  /// [onComplete]는 복구가 성공적으로 완료되었을 때 호출되는 콜백 함수입니다.
  /// [onError]는 복구 중 오류가 발생했을 때 호출되는 콜백 함수입니다.
  /// [onCancel]은 사용자가 취소했을 때 호출되는 콜백 함수입니다.
  const RecoveryProgressModal({
    required this.noteId,
    required this.noteTitle,
    required this.onComplete,
    required this.onError,
    required this.onCancel,
    super.key,
  });

  /// 복구할 노트의 고유 ID.
  final String noteId;

  /// 복구할 노트의 제목.
  final String noteTitle;

  /// 복구가 성공적으로 완료되었을 때 호출되는 콜백 함수.
  final VoidCallback onComplete;

  /// 복구 중 오류가 발생했을 때 호출되는 콜백 함수.
  final VoidCallback onError;

  /// 사용자가 취소했을 때 호출되는 콜백 함수.
  final VoidCallback onCancel;

  @override
  ConsumerState<RecoveryProgressModal> createState() => _RecoveryProgressModalState();
}

class _RecoveryProgressModalState extends ConsumerState<RecoveryProgressModal> {
  double _progress = 0.0;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _canCancel = true;
  bool _isCancelled = false;
  bool _isCompleted = false;
  String _statusMessage = 'PDF 복구를 준비하고 있습니다...';

  @override
  void initState() {
    super.initState();
    _startRerendering();
  }

  /// 재렌더링 프로세스를 시작합니다.
  Future<void> _startRerendering() async {
    try {
      setState(() {
        _statusMessage = 'PDF 페이지를 다시 렌더링하고 있습니다...';
      });

      final repo = ref.watch(notesRepositoryProvider);

      final success = await PdfRecoveryService.rerenderNotePages(
        widget.noteId,
        repo: repo,
        onProgress: (progress, current, total) {
          if (mounted && !_isCancelled && !_isCompleted) {
            setState(() {
              _progress = progress;
              _currentPage = current;
              _totalPages = total;
              _statusMessage = '페이지 $current/$total 렌더링 중...';
            });
          }
        },
      );

      if (mounted && !_isCancelled) {
        _isCompleted = true;
        if (success) {
          setState(() {
            _progress = 1.0;
            _statusMessage = '복구가 완료되었습니다!';
            _canCancel = false;
          });

          // 잠시 완료 상태를 보여준 후 콜백 호출
          await Future<void>.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            widget.onComplete();
          }
        } else {
          setState(() {
            _statusMessage = '복구 중 오류가 발생했습니다.';
            _canCancel = false;
          });
          widget.onError();
        }
      }
    } catch (e) {
      debugPrint('❌ 재렌더링 중 예외 발생: $e');
      if (mounted && !_isCancelled) {
        setState(() {
          _statusMessage = '복구 중 오류가 발생했습니다: $e';
          _canCancel = false;
        });
        widget.onError();
      }
    }
  }

  /// 재렌더링을 취소합니다.
  void _cancelRerendering() {
    if (!_canCancel || _isCancelled || _isCompleted) {
      return;
    }

    setState(() {
      _isCancelled = true;
      _canCancel = false;
      _statusMessage = '취소 중...';
    });

    // PdfRecoveryService에 취소 신호 전송
    PdfRecoveryService.cancelRerendering();

    // 잠시 후 취소 콜백 호출
    Future<void>.delayed(const Duration(milliseconds: 300)).then((_) {
      if (mounted) {
        widget.onCancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로가기 방지
      child: AlertDialog(
        title: Text(
          '노트 복구 중',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isCancelled
                ? Colors.orange[700]
                : _isCompleted
                ? Colors.green[700]
                : Colors.blue[700],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 노트 제목 표시
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.noteTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 진행 상태 표시
            if (_isCancelled)
              Column(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    size: 48,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else if (_isCompleted && _progress >= 1.0)
              Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.green[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // 원형 진행률 표시기
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[600]!,
                      ),
                      strokeWidth: 6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 상태 메시지
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 선형 진행률 표시기 (페이지 정보가 있을 때만)
                  if (_totalPages > 0) ...[
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[600]!,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '진행률: $_currentPage / $_totalPages 페이지',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

            // 주의사항 안내
            if (!_isCancelled && !_isCompleted) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.yellow[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '복구가 진행 중입니다. 잠시만 기다려주세요.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: _buildActionButtons(),
      ),
    );
  }

  /// 액션 버튼들을 생성합니다.
  List<Widget> _buildActionButtons() {
    if (_isCancelled || _isCompleted) {
      return []; // 완료되거나 취소된 경우 버튼 숨김
    }

    if (_canCancel) {
      return [
        TextButton.icon(
          onPressed: _cancelRerendering,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('취소'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[600],
          ),
        ),
      ];
    }

    return [];
  }

  // static show 메서드 제거됨
  // 이유: IDE에서 메서드 인식 오류로 인해 showDialog를 직접 사용하는 방식으로 변경
  // canvas_background_widget.dart에서 showDialog<void>(...) 패턴으로 호출
}
