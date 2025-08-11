import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../../../shared/services/note_service.dart';
import '../../../shared/widgets/navigation_card.dart';
import '../data/derived_note_providers.dart';
import '../data/notes_repository_provider.dart';

/// 노트 목록을 표시하고 새로운 노트를 생성하는 화면입니다.
///
/// 위젯 계층 구조:
/// MyApp
/// ㄴ HomeScreen
///   ㄴ NavigationCard → 라우트 이동 (/notes) → (현 위젯)
class NoteListScreen extends ConsumerStatefulWidget {
  /// [NoteListScreen]의 생성자.
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen> {
  bool _isImporting = false;

  /// PDF 파일을 선택하고 노트로 가져옵니다.
  Future<void> _importPdfNote() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);

    try {
      final pdfNote = await NoteService.instance.createPdfNote();

      if (pdfNote != null) {
        final repo = ref.read(notesRepositoryProvider);
        repo.upsert(pdfNote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF 노트 "${pdfNote.title}"가 성공적으로 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 노트 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _createBlankNote() async {
    try {
      final blankNote = await NoteService.instance.createBlankNote();
      final repo = ref.read(notesRepositoryProvider);

      if (blankNote != null) {
        repo.upsert(blankNote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('빈 노트 "${blankNote.title}"가 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('노트 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '노트 목록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6750A4),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎯 노트 목록 영역
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.1).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '저장된 노트들',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1B1F),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 저장된 노트로 이동하는 카드들 (provider 기반)
                      notesAsync.when(
                        data: (notes) {
                          if (notes.isEmpty) {
                            return const Text('저장된 노트가 없습니다.');
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < notes.length; i++) ...[
                                NavigationCard(
                                  icon: Icons.brush,
                                  title: notes[i].title,
                                  subtitle: '${notes[i].pages.length} 페이지',
                                  color: const Color(0xFF6750A4),
                                  onTap: () {
                                    debugPrint('📝 노트 편집: ${notes[i].noteId}');
                                    context.pushNamed(
                                      AppRoutes.noteEditName,
                                      pathParameters: {
                                        'noteId': notes[i].noteId,
                                      },
                                    );
                                  },
                                ),
                                if (i < notes.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stackTrace) => Center(
                          child: Text('오류: $error'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // PDF 가져오기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importPdfNote,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _isImporting ? 'PDF 가져오는 중...' : 'PDF 파일에서 노트 생성',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 노트 생성 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF6750A4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFF6750A4),
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () => _createBlankNote(),
                    child: const Text('노트 생성'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
