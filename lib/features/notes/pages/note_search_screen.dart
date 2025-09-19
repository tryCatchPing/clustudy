import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../../../shared/widgets/navigation_card.dart';
import '../providers/note_list_controller.dart';

/// 노트 검색 전용 화면.
class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  late final TextEditingController _searchCtrl;

  NoteListController get _actions =>
      ref.read(noteListControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    // 검색 화면 진입 시 기존 검색 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _actions.clearSearch();
    });
  }

  @override
  void dispose() {
    _actions.clearSearch();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _actions.updateSearchQuery(value);
  }

  void _clearQuery() {
    _searchCtrl.clear();
    _actions.clearSearch();
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
      appBar: AppBar(
        title: const Text('노트 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: '노트 제목 검색',
                hintText: '검색어를 입력하세요',
                border: const OutlineInputBorder(),
                suffixIcon: state.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearQuery,
                        icon: const Icon(Icons.clear),
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (state.searchQuery.isEmpty) {
                    return const Center(
                      child: Text('검색어를 입력하면 결과가 표시됩니다.'),
                    );
                  }
                  if (state.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state.searchResults.isEmpty) {
                    return const Center(
                      child: Text('검색 결과가 없습니다.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: state.searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final result = state.searchResults[index];
                      return NavigationCard(
                        icon: Icons.brush,
                        title: result.title,
                        subtitle: result.parentFolderName ?? '루트',
                        color: const Color(0xFF6750A4),
                        onTap: () {
                          context.pushNamed(
                            AppRoutes.noteEditName,
                            pathParameters: {'noteId': result.noteId},
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
