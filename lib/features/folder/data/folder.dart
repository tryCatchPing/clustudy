class Folder {
  final String id;
  final String vaultId;
  final String name;
  final DateTime createdAt;
  final String? parentFolderId; // null이면 vault의 최상위 폴더

  Folder({
    required this.id,
    required this.vaultId,
    required this.name,
    required this.createdAt,
    this.parentFolderId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vaultId': vaultId,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'parentFolderId': parentFolderId,
  };

  factory Folder.fromJson(Map<String, dynamic> j) => Folder(
    id: j['id'],
    vaultId: j['vaultId'],
    name: j['name'],
    createdAt: DateTime.parse(j['createdAt']),
    parentFolderId: j['parentFolderId'],
  );
}
