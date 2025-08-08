import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/services/file_storage_service.dart';
import '../../../shared/routing/app_routes.dart';
import '../../../shared/services/pdf_recovery_service.dart';
import '../../notes/models/note_page_model.dart';
import 'recovery_options_modal.dart';
import 'recovery_progress_modal.dart';

/// 캔버스 배경을 표시하는 위젯
///
/// 페이지 타입에 따라 빈 캔버스 또는 PDF 페이지를 표시합니다.
///
/// 로딩 시스템:
/// 1. 사전 렌더링된 로컬 이미지 파일 로드
/// 2. 파일 손상 시 PdfRecoveryService를 통한 복구 옵션 제공
///
/// 위젯 계층 구조:
/// MyApp
/// ㄴ HomeScreen
///   ㄴ NavigationCard → 라우트 이동 (/notes) → NoteListScreen
///     ㄴ NavigationCard → 라우트 이동 (/notes/:noteId/edit) → NoteEditorScreen
///       ㄴ NoteEditorCanvas
///         ㄴ NotePageViewItem
///           ㄴ (현 위젯) / Scribble
class CanvasBackgroundWidget extends StatefulWidget {
  /// [CanvasBackgroundWidget]의 생성자.
  ///
  /// [page]는 현재 노트 페이지 모델입니다.
  /// [width]는 캔버스 너비입니다.
  /// [height]는 캔버스 높이입니다.
  const CanvasBackgroundWidget({
    required this.page,
    required this.width,
    required this.height,
    super.key,
  });

  /// 현재 노트 페이지 모델.
  final NotePageModel page;

  /// 캔버스 너비.
  ///
  /// 원본 PDF 크기 기준으로 2000px 긴 변에 맞춰 비율 조정된 값입니다.
  final double width;

  /// 캔버스 높이.
  final double height;

  @override
  State<CanvasBackgroundWidget> createState() => _CanvasBackgroundWidgetState();
}

class _CanvasBackgroundWidgetState extends State<CanvasBackgroundWidget> {
  bool _isLoading = false;
  String? _errorMessage;
  File? _preRenderedImageFile;
  bool _hasCheckedPreRenderedImage = false;
  bool _isRecovering = false;

  @override
  void initState() {
    super.initState();

    if (widget.page.hasPdfBackground) {
      // 배경 이미지 (PDF) 로딩
      _loadBackgroundImage();
    }
  }

  /// Called when the widget configuration changes.
  ///
  /// If the note page changes and has a PDF background, reload the background.
  ///
  /// [oldWidget] is the previous widget instance.
  /// [widget] is the current widget instance.
  @override
  void didUpdateWidget(CanvasBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page.hasPdfBackground && oldWidget.page != widget.page) {
      _hasCheckedPreRenderedImage = false;
      _preRenderedImageFile = null;
      _loadBackgroundImage();
    }
  }

  /// 배경 이미지를 로딩하는 메인 메서드
  ///
  /// 사전 렌더링된 이미지 파일을 로드하고, 실패 시 복구 모달 표시
  Future<void> _loadBackgroundImage() async {
    if (!widget.page.hasPdfBackground) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🎯 배경 이미지 로딩 시작: ${widget.page.pageId}');

      // 1. 사전 렌더링된 로컬 이미지 확인
      if (!_hasCheckedPreRenderedImage) {
        await _checkPreRenderedImage();
      }

      // 사전 렌더링된 이미지 파일이 있으면 사용
      if (_preRenderedImageFile != null) {
        debugPrint('✅ 사전 렌더링된 이미지 사용: ${_preRenderedImageFile!.path}');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. 파일이 없거나 손상된 경우 복구 시스템 호출
      debugPrint('❌ 사전 렌더링된 이미지를 찾을 수 없음 - 복구 시스템 호출');
      await _handleFileCorruption();
      return;
    } catch (e) {
      debugPrint('❌ 배경 이미지 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '배경 이미지 로딩 실패: $e';
        });
        await _handleFileCorruption();
      }
    }
  }

  /// 사전 렌더링된 이미지 파일 확인
  Future<void> _checkPreRenderedImage() async {
    _hasCheckedPreRenderedImage = true;

    try {
      // NotePageModel에 이미지 경로가 있는 경우
      if (widget.page.preRenderedImagePath != null) {
        final imageFile = File(widget.page.preRenderedImagePath!);
        if (await imageFile.exists()) {
          _preRenderedImageFile = imageFile;
          return;
        }
      }

      // FileStorageService를 통해 이미지 경로 확인
      final imagePath = await FileStorageService.getPageImagePath(
        noteId: widget.page.noteId,
        pageNumber: widget.page.pageNumber,
      );

      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          _preRenderedImageFile = imageFile;
        }
      }
    } catch (e) {
      debugPrint('⚠️ 사전 렌더링된 이미지 확인 실패: $e');
    }
  }

  /// 재시도 버튼 클릭 시 호출
  Future<void> _retryLoading() async {
    _hasCheckedPreRenderedImage = false;
    _preRenderedImageFile = null;
    await _loadBackgroundImage();
  }

  /// 파일 손상을 처리합니다.
  Future<void> _handleFileCorruption() async {
    if (_isRecovering) {
      return; // 이미 복구 중인 경우 중복 실행 방지
    }

    setState(() {
      _isRecovering = true;
    });

    try {
      // 손상 유형 감지
      final corruptionType = await PdfRecoveryService.detectCorruption(
        widget.page,
      );

      // 노트 제목 추출
      final noteTitle = widget.page.noteId.replaceAll('_', ' ');

      if (mounted) {
        // 복구 옵션 모달 표시
        await RecoveryOptionsModal.show(
          context,
          corruptionType: corruptionType,
          noteTitle: noteTitle,
          onRerender: () => _handleRerender(noteTitle),
          onSketchOnly: _handleSketchOnlyMode,
          onDelete: () => _handleNoteDelete(noteTitle),
        );
      }
    } catch (e) {
      debugPrint('❌ 파일 손상 처리 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('파일 손상 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  /// 재렌더링을 처리합니다.
  Future<void> _handleRerender(String noteTitle) async {
    if (!mounted) {
      return;
    }

    // 재렌더링 진행률 모달 표시
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecoveryProgressModal(
        noteId: widget.page.noteId,
        noteTitle: noteTitle,
        onComplete: () {
          // 모달 닫기
          context.pop();
          // 위젯 새로고침
          _refreshWidget();
        },
        onError: () {
          // 모달 닫기
          context.pop();
          // 에러 메시지 표시
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('재렌더링 중 오류가 발생했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onCancel: () {
          // 모달 닫기
          context.pop();
          // 취소 메시지 표시
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('재렌더링이 취소되었습니다.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }

  /// 필기만 보기 모드를 활성화합니다.
  Future<void> _handleSketchOnlyMode() async {
    try {
      await PdfRecoveryService.enableSketchOnlyMode(widget.page.noteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('필기만 보기 모드가 활성화되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 위젯 새로고침
        _refreshWidget();
      }
    } catch (e) {
      debugPrint('❌ 필기만 보기 모드 활성화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('필기만 보기 모드 활성화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 노트를 삭제합니다.
  Future<void> _handleNoteDelete(String noteTitle) async {
    // 삭제 확인 다이얼로그
    final shouldDelete = await _showDeleteConfirmation(noteTitle);
    if (!shouldDelete || !mounted) {
      return;
    }

    try {
      final success = await PdfRecoveryService.deleteNoteCompletely(
        widget.page.noteId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('노트가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 노트 목록으로 돌아가기
        if (mounted) {
          context.goNamed(AppRoutes.noteListName);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('노트 삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 노트 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('노트 삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 삭제 확인 다이얼로그를 표시합니다.
  Future<bool> _showDeleteConfirmation(String noteTitle) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('노트 삭제 확인'),
            content: Text(
              '정말로 "$noteTitle" 노트를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
              onPressed: () => context.pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => context.pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 위젯을 새로고침합니다.
  void _refreshWidget() {
    setState(() {
      _hasCheckedPreRenderedImage = false;
      _preRenderedImageFile = null;
      _errorMessage = null;
    });
    _loadBackgroundImage();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildBackground(),
    );
  }

  Widget _buildBackground() {
    if (widget.page.hasPdfBackground) {
      return _buildPdfBackground();
    } else {
      return _buildBlankBackground();
    }
  }

  Widget _buildPdfBackground() {
    // 필기만 보기 모드인 경우 배경 이미지 숨김
    if (!widget.page.showBackgroundImage) {
      return _buildSketchOnlyBackground();
    }

    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorIndicator();
    }

    // 사전 렌더링된 이미지 파일 표시
    if (_preRenderedImageFile != null) {
      return Image.file(
        _preRenderedImageFile!,
        fit: BoxFit.contain,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('⚠️ 사전 렌더링된 이미지 로딩 오류: $error');
          // 이미지 파일 오류 시 에러 표시
          return _buildErrorIndicator();
        },
      );
    }

    // 파일이 없으면 로딩 표시
    return _buildLoadingIndicator();
  }

  /// 필기만 보기 모드를 위한 배경을 생성합니다.
  Widget _buildSketchOnlyBackground() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              '필기만 보기 모드',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '배경 이미지가 숨겨져 있습니다',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankBackground() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'PDF 페이지 로딩 중...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(
          color: Colors.red[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'PDF 로딩 실패',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
