class Vault {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isTemporary;

  Vault({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isTemporary = false,
  });

  factory Vault.temp() => Vault(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '임시 vault 폴더',
        createdAt: DateTime.now(),
        isTemporary: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'isTemporary': isTemporary,
      };

  factory Vault.fromJson(Map<String, dynamic> j) => Vault(
        id: j['id'],
        name: j['name'],
        createdAt: DateTime.parse(j['createdAt']),
        isTemporary: j['isTemporary'] ?? false,
      );
}
