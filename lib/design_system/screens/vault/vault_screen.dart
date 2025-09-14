import 'package:flutter/material.dart';

/// Minimal vault screen showcase so designers can iterate on layout without the
/// feature layer. Later commits refine this with the real styling coming from
/// Yura's work.
class DesignVaultScreen extends StatelessWidget {
  const DesignVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _vaultItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault 상세'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 3 / 4,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final note = items[index];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      note.description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.updatedAt,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSnack(context, '노트 추가'),
        label: const Text('노트 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 800)),
    );
  }
}

class _VaultNote {
  const _VaultNote({
    required this.title,
    required this.description,
    required this.updatedAt,
  });

  final String title;
  final String description;
  final String updatedAt;
}

const List<_VaultNote> _vaultItems = [
  _VaultNote(
    title: '강의 필기',
    description: '미적분학 3주차 노트. 그래프와 중요 개념 요약.',
    updatedAt: '2025.08.29',
  ),
  _VaultNote(
    title: 'PDF 요약',
    description: '논문 요약 PDF 하이라이트 정리.',
    updatedAt: '2025.08.25',
  ),
  _VaultNote(
    title: '아이디어 스케치',
    description: '제품 컨셉 스케치 이미지 모음.',
    updatedAt: '2025.08.22',
  ),
  _VaultNote(
    title: '미팅 노트',
    description: '팀 미팅 메모와 액션 아이템.',
    updatedAt: '2025.08.21',
  ),
  _VaultNote(
    title: '연구 자료',
    description: '참고 논문 링크 및 요약 정리.',
    updatedAt: '2025.08.18',
  ),
];
