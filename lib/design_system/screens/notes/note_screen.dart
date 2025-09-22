import 'package:flutter/material.dart';

/// Simplified note list showcase used only inside the design system. The
/// feature counterpart depends on repositories and providers; here we keep a
/// deterministic set of cards so designers can tweak visual elements without
/// wiring real data.
class DesignNoteScreen extends StatelessWidget {
  const DesignNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const notes = _demoNotes;
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
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '노트 관리',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '최근 생성한 노트와 PDF를 빠르게 확인하세요.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          FilledButton(
                            onPressed: () => _showSnack(context, '새 노트 생성'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6750A4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('새 노트 만들기'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _NoteCard(note: note);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ImportSection(onTap: () => _showSnack(context, 'PDF 가져오기')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 800)),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final _DemoNote note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.description,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                note.updatedAt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showSnack(context, '노트 열기'),
                    icon: const Icon(Icons.open_in_new),
                  ),
                  IconButton(
                    onPressed: () => _showSnack(context, '노트 삭제'),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 600)),
    );
  }
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, size: 32, color: Color(0xFF6750A4)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF 가져오기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PDF 파일을 가져와 새로운 노트를 생성하세요.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onTap,
            child: const Text('파일 선택'),
          ),
        ],
      ),
    );
  }
}

class _DemoNote {
  const _DemoNote({
    required this.title,
    required this.description,
    required this.updatedAt,
  });

  final String title;
  final String description;
  final String updatedAt;
}

const List<_DemoNote> _demoNotes = [
  _DemoNote(
    title: 'UX 리서치 정리',
    description: '사용자 인터뷰 핵심 인사이트와 문제 정의.',
    updatedAt: '2025.09.03 18:20',
  ),
  _DemoNote(
    title: '수학 기출 분석',
    description: '벡터 단원 오답 노트. 그래프 필기 포함.',
    updatedAt: '2025.09.02 09:12',
  ),
  _DemoNote(
    title: '팀 회의 메모',
    description: 'Sprint 12 회의록 및 TODO 정리.',
    updatedAt: '2025.08.30 13:45',
  ),
];
