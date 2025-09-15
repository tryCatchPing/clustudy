class Note {
  final String id;
  final String vaultId;
  final String title;
  final DateTime createdAt;
  final bool isPdf;
  final String? pdfName; // 파일명만 보관 (경로/바이트 영속화는 추후)
  final String? folderId;


  Note({
    required this.id,
    required this.vaultId,
    this.folderId,
    required this.title,
    required this.createdAt,
    this.isPdf = false,
    this.pdfName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vaultId': vaultId,
    'folderId': folderId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'isPdf': isPdf,
    'pdfName': pdfName,
  };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'],
    vaultId: j['vaultId'],
    folderId: j['folderId'],
    title: j['title'],
    createdAt: DateTime.parse(j['createdAt']),
    isPdf: j['isPdf'] ?? false,
    pdfName: j['pdfName'],
  );
}
