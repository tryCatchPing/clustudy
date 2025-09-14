import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'vault.dart';

class VaultRepository {
  static const _k = 'vaults';

  Future<List<Vault>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? [];
    return raw.map((s) => Vault.fromJson(jsonDecode(s))).toList();
  }

  Future<void> save(List<Vault> items) async {
    final p = await SharedPreferences.getInstance();
    final raw = items.map((v) => jsonEncode(v.toJson())).toList();
    await p.setStringList(_k, raw);
  }
}
