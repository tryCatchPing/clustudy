import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/molecules/note_card.dart';
import '../../../design_system/components/organisms/search_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../shared/routing/app_routes.dart';
import '../providers/note_list_controller.dart';

/// 노트 검색 전용 화면.
class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;

  NoteListController get _actions =>
      ref.read(noteListControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _actions.updateSearchQuery(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NoteListState>(
      noteListControllerProvider,
      (previous, next) {
        if (_searchCtrl.text == next.searchQuery) return;
        _searchCtrl
          ..text = next.searchQuery
          ..selection = TextSelection.collapsed(
            offset: next.searchQuery.length,
          );
      },
    );

    final state = ref.watch(noteListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SearchToolbar(
        controller: _searchCtrl,
        onBack: () => context.pop(),
        onDone: () {}, // 검색은 onChange로 이미 처리됨
        backSvgPath: AppIcons.chevronLeft,
        searchSvgPath: AppIcons.search,
        clearSvgPath: AppIcons.roundX,
        autofocus: true,
        onChanged: _onQueryChanged,
        onSubmitted: (_) {}, // 검색은 onChange로 이미 처리됨
      ),
      body: Builder(
        builder: (_) {
          if (state.searchQuery.isEmpty) {
            return const _NoteSearchEmptyState(
              message: '검색어를 입력하세요',
            );
          }
          if (state.isSearching) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state.searchResults.isEmpty) {
            return const _NoteSearchEmptyState(
              message: '검색 결과가 없습니다',
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.large,
            ),
            child: Wrap(
              spacing: AppSpacing.large,
              runSpacing: AppSpacing.large,
              children: state.searchResults.map((result) {
                return NoteCard(
                  iconPath: AppIcons.noteAdd,
                  title: result.title,
                  date: DateTime.now(), // TODO: 실제 노트 업데이트 날짜로 교체
                  onTap: () {
                    context.pushNamed(
                      AppRoutes.noteEditName,
                      pathParameters: {'noteId': result.noteId},
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// 노트 검색 전용 빈 상태 위젯 (디자인 시스템 스타일)
class _NoteSearchEmptyState extends StatelessWidget {
  const _NoteSearchEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 디자인 토큰 아이콘 사용
          SvgPicture.asset(
            AppIcons.searchLarge,
            width: 144,
            height: 144,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.body2.copyWith(color: AppColors.gray40),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
