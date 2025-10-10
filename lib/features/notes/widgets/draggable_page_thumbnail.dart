import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../shared/services/page_thumbnail_service.dart';
import '../data/notes_repository_provider.dart';
import '../models/note_page_model.dart';

/// 드래그 가능한 페이지 썸네일 위젯입니다.
///
/// 길게 누르기로 드래그 모드를 활성화하고, 썸네일 이미지를 표시하며,
/// 로딩 상태를 처리하고, 삭제 버튼 오버레이를 제공합니다.
class DraggablePageThumbnail extends ConsumerStatefulWidget {
  /// 표시할 페이지 모델.
  final NotePageModel page;

  /// 썸네일 이미지 데이터 (null이면 자동 로딩).
  final Uint8List? thumbnail;

  /// 썸네일 자동 로딩 여부 (기본값: true).
  final bool autoLoadThumbnail;

  /// 드래그 중인지 여부.
  final bool isDragging;

  /// 삭제 버튼 클릭 콜백.
  final VoidCallback? onDelete;

  /// 썸네일 탭 콜백.
  final VoidCallback? onTap;

  /// 드래그 시작 콜백.
  final VoidCallback? onDragStart;

  /// 드래그 종료 콜백.
  final VoidCallback? onDragEnd;

  /// 썸네일 크기 (기본값: 120).
  final double size;

  /// 삭제 버튼 표시 여부 (기본값: true).
  final bool showDeleteButton;

  /// [DraggablePageThumbnail]의 생성자.
  const DraggablePageThumbnail({
    super.key,
    required this.page,
    this.thumbnail,
    this.autoLoadThumbnail = true,
    this.isDragging = false,
    this.onDelete,
    this.onTap,
    this.onDragStart,
    this.onDragEnd,
    this.size = 120,
    this.showDeleteButton = true,
  });

  @override
  ConsumerState<DraggablePageThumbnail> createState() =>
      _DraggablePageThumbnailState();
}

class _DraggablePageThumbnailState extends ConsumerState<DraggablePageThumbnail>
    with TickerProviderStateMixin {
  /// 드래그 모드 활성화 여부.
  bool _isDragModeActive = false;

  /// 로드된 썸네일 데이터.
  Uint8List? _loadedThumbnail;

  /// 썸네일 로딩 중 여부.
  bool _isLoading = false;

  /// 썸네일 로딩 오류.
  String? _loadingError;

  /// 길게 누르기 애니메이션 컨트롤러.
  late AnimationController _longPressController;

  /// 드래그 애니메이션 컨트롤러.
  late AnimationController _dragController;

  /// 스케일 애니메이션.
  late Animation<double> _scaleAnimation;

  /// 드래그 스케일 애니메이션.
  late Animation<double> _dragScaleAnimation;

  /// 삭제 버튼 표시 애니메이션.
  late Animation<double> _deleteButtonAnimation;

  @override
  void initState() {
    super.initState();

    // 길게 누르기 애니메이션 설정
    _longPressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // 드래그 애니메이션 설정
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 스케일 애니메이션 설정
    _scaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).animate(
          CurvedAnimation(
            parent: _longPressController,
            curve: Curves.easeInOut,
          ),
        );

    // 드래그 스케일 애니메이션 설정
    _dragScaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.1,
        ).animate(
          CurvedAnimation(
            parent: _dragController,
            curve: Curves.easeInOut,
          ),
        );

    // 삭제 버튼 애니메이션 설정
    _deleteButtonAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _dragController,
            curve: Curves.easeInOut,
          ),
        );

    // 썸네일 자동 로딩 시작
    if (widget.autoLoadThumbnail && widget.thumbnail == null) {
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _longPressController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggablePageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 드래그 상태 변경에 따른 애니메이션 처리
    if (widget.isDragging != oldWidget.isDragging) {
      if (widget.isDragging) {
        _dragController.forward();
      } else {
        _dragController.reverse();
        _isDragModeActive = false;
      }
    }
  }

  /// 길게 누르기 시작 처리.
  void _onLongPressStart(LongPressStartDetails details) {
    _longPressController.forward();
  }

  /// 길게 누르기 종료 처리.
  void _onLongPressEnd(LongPressEndDetails details) {
    _longPressController.reverse();

    if (!_isDragModeActive) {
      _isDragModeActive = true;
      widget.onDragStart?.call();
    }
  }

  /// 길게 누르기 취소 처리.
  void _onLongPressCancel() {
    _longPressController.reverse();
  }

  /// 썸네일 탭 처리.
  void _onTap() {
    if (!widget.isDragging && !_isDragModeActive) {
      widget.onTap?.call();
    }
  }

  /// 삭제 버튼 탭 처리.
  void _onDeleteTap() {
    widget.onDelete?.call();
  }

  /// 썸네일을 로드합니다.
  Future<void> _loadThumbnail() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      final repository = ref.read(notesRepositoryProvider);
      final thumbnail = await PageThumbnailService.getOrGenerateThumbnail(
        widget.page,
        repository,
      );

      if (mounted) {
        setState(() {
          _loadedThumbnail = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _dragScaleAnimation,
        _deleteButtonAnimation,
      ]),
      builder: (context, child) {
        final scale = _scaleAnimation.value * _dragScaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Draggable<NotePageModel>(
            data: widget.page,
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.1,
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildThumbnailContent(),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _buildThumbnailContent(),
              ),
            ),
            onDragStarted: () {
              widget.onDragStart?.call();
            },
            onDragEnd: (details) {
              widget.onDragEnd?.call();
            },
            child: GestureDetector(
              onTap: _onTap,
              onLongPressStart: _onLongPressStart,
              onLongPressEnd: _onLongPressEnd,
              onLongPressCancel: _onLongPressCancel,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    if (widget.isDragging)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 썸네일 이미지 또는 로딩/플레이스홀더
                    _buildThumbnailContent(),

                    // 페이지 번호 오버레이
                    _buildPageNumberOverlay(),

                    // 삭제 버튼 오버레이
                    if (widget.showDeleteButton) _buildDeleteButtonOverlay(),

                    // 드래그 상태 오버레이
                    if (widget.isDragging) _buildDragOverlay(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 썸네일 콘텐츠를 빌드합니다.
  Widget _buildThumbnailContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.small),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.gray10,
          border: Border.all(
            color: AppColors.gray20,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
        child: _buildThumbnailChild(),
      ),
    );
  }

  /// 썸네일 자식 위젯을 빌드합니다.
  Widget _buildThumbnailChild() {
    // 외부에서 제공된 썸네일이 있으면 우선 사용
    if (widget.thumbnail != null) {
      return _buildThumbnailImage(widget.thumbnail!);
    }

    // 로딩 중이면 로딩 인디케이터 표시
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    // 로드된 썸네일이 있으면 표시
    if (_loadedThumbnail != null) {
      return _buildThumbnailImage(_loadedThumbnail!);
    }

    // 로딩 오류가 있으면 오류 표시
    if (_loadingError != null) {
      return _buildErrorPlaceholder();
    }

    // 기본 플레이스홀더 표시
    return _buildPlaceholder();
  }

  /// 로딩 인디케이터를 빌드합니다.
  Widget _buildLoadingIndicator() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 썸네일 이미지를 빌드합니다.
  Widget _buildThumbnailImage(Uint8List thumbnailData) {
    return Image.memory(
      thumbnailData,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  /// 오류 플레이스홀더를 빌드합니다.
  Widget _buildErrorPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.errorLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 32,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '로드 실패',
            style: AppTypography.caption.copyWith(
              color: AppColors.errorDark,
            ),
          ),
        ],
      ),
    );
  }

  /// 플레이스홀더를 빌드합니다.
  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.gray10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.page.backgroundType == PageBackgroundType.pdf
                ? Icons.picture_as_pdf
                : Icons.note,
            size: 32,
            color: AppColors.gray30,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '페이지 ${widget.page.pageNumber}',
            style: AppTypography.caption.copyWith(
              color: AppColors.gray40,
            ),
          ),
        ],
      ),
    );
  }

  /// 페이지 번호 오버레이를 빌드합니다.
  Widget _buildPageNumberOverlay() {
    return Positioned(
      bottom: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray50.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Text(
          '${widget.page.pageNumber}',
          style: AppTypography.caption.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 삭제 버튼 오버레이를 빌드합니다.
  Widget _buildDeleteButtonOverlay() {
    return Positioned(
      top: -4,
      right: -4,
      child: AnimatedBuilder(
        animation: _deleteButtonAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _deleteButtonAnimation.value,
            child: Opacity(
              opacity: _deleteButtonAnimation.value,
              child: GestureDetector(
                onTap: _onDeleteTap,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 드래그 상태 오버레이를 빌드합니다.
  Widget _buildDragOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.small),
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.small),
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }
}
