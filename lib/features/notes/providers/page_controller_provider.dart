import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/services/page_management_service.dart';
import '../data/notes_repository_provider.dart';
import '../models/note_page_model.dart';

part 'page_controller_provider.g.dart';

/// 페이지 컨트롤러 화면의 상태를 관리하는 provider입니다.
@riverpod
class PageControllerScreenNotifier extends _$PageControllerScreenNotifier {
  @override
  PageControllerScreenState build(String noteId) {
    return const PageControllerScreenState();
  }

  /// 페이지 추가 기능을 실행합니다.
  Future<void> addBlankPage() async {
    state = state.copyWith(isLoading: true, operation: '페이지 추가 중...');

    try {
      final repository = ref.read(notesRepositoryProvider);
      final note = await repository.getNoteById(noteId);

      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다');
      }

      // 새 페이지 번호 계산 (마지막 페이지 + 1)
      final newPageNumber = note.pages.length + 1;

      // 빈 페이지 생성
      final newPage = await PageManagementService.createBlankPage(
        noteId,
        newPageNumber,
      );

      if (newPage == null) {
        throw Exception('페이지 생성에 실패했습니다');
      }

      // Repository를 통해 페이지 추가
      await PageManagementService.addPage(
        noteId,
        newPage,
        repository,
      );

      state = state.copyWith(
        isLoading: false,
        operation: null,
        hasUnsavedChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        operation: null,
        errorMessage: '페이지 추가 실패: $e',
      );
    }
  }

  /// 페이지 삭제 기능을 실행합니다.
  Future<void> deletePage(NotePageModel page) async {
    state = state.copyWith(isLoading: true, operation: '페이지 삭제 중...');

    try {
      final repository = ref.read(notesRepositoryProvider);
      final note = await repository.getNoteById(noteId);

      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다');
      }

      // 마지막 페이지 삭제 방지
      if (!PageManagementService.canDeletePage(note, page.pageId)) {
        throw Exception('마지막 페이지는 삭제할 수 없습니다');
      }

      // Repository를 통해 페이지 삭제
      await PageManagementService.deletePage(
        noteId,
        page.pageId,
        repository,
      );

      state = state.copyWith(
        isLoading: false,
        operation: null,
        hasUnsavedChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        operation: null,
        errorMessage: '페이지 삭제 실패: $e',
      );
    }
  }

  /// 변경사항 저장 상태를 설정합니다.
  void setUnsavedChanges(bool hasChanges) {
    state = state.copyWith(hasUnsavedChanges: hasChanges);
  }

  /// 오류 상태를 클리어합니다.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 로딩 상태를 설정합니다.
  void setLoading(bool isLoading, {String? operation}) {
    state = state.copyWith(
      isLoading: isLoading,
      operation: operation,
    );
  }
}

/// 페이지 컨트롤러 화면의 상태를 나타내는 클래스입니다.
class PageControllerScreenState {
  /// 로딩 중인지 여부
  final bool isLoading;

  /// 현재 진행 중인 작업
  final String? operation;

  /// 오류 메시지
  final String? errorMessage;

  /// 저장되지 않은 변경사항이 있는지 여부
  final bool hasUnsavedChanges;

  const PageControllerScreenState({
    this.isLoading = false,
    this.operation,
    this.errorMessage,
    this.hasUnsavedChanges = false,
  });

  PageControllerScreenState copyWith({
    bool? isLoading,
    String? operation,
    String? errorMessage,
    bool? hasUnsavedChanges,
  }) {
    return PageControllerScreenState(
      isLoading: isLoading ?? this.isLoading,
      operation: operation ?? this.operation,
      errorMessage: errorMessage ?? this.errorMessage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageControllerScreenState &&
        other.isLoading == isLoading &&
        other.operation == operation &&
        other.errorMessage == errorMessage &&
        other.hasUnsavedChanges == hasUnsavedChanges;
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      operation,
      errorMessage,
      hasUnsavedChanges,
    );
  }
}
