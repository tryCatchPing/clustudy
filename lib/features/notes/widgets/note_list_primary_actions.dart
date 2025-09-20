import 'package:flutter/material.dart';

class NoteListPrimaryActions extends StatelessWidget {
  const NoteListPrimaryActions({
    super.key,
    required this.isImporting,
    required this.onImportPdf,
    required this.onCreateBlankNote,
  });

  final bool isImporting;
  final VoidCallback onImportPdf;
  final VoidCallback onCreateBlankNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isImporting ? null : onImportPdf,
            icon: isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
              isImporting ? 'PDF 불러오는 중...' : 'PDF 파일로 노트 생성',
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
            onPressed: onCreateBlankNote,
            child: const Text('노트 만들기'),
          ),
        ),
      ],
    );
  }
}
