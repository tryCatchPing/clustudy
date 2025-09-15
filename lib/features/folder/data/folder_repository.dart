import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'folder.dart';

class FolderRepository {
  static const _k = 'folders';

  Future<List<Folder>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? [];
    return raw.map((s) => Folder.fromJson(jsonDecode(s))).toList();
  }

  Future<void> save(List<Folder> items) async {
    final p = await SharedPreferences.getInstance();
    final raw = items.map((e) => jsonEncode(e.toJson())).toList();
    await p.setStringList(_k, raw);
  }
}
