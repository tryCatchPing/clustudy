import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'note.dart';

class NoteRepository {
  static const _k = 'notes';

  Future<List<Note>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? [];
    return raw.map((s) => Note.fromJson(jsonDecode(s))).toList();
  }

  Future<void> save(List<Note> items) async {
    final p = await SharedPreferences.getInstance();
    final raw = items.map((e) => jsonEncode(e.toJson())).toList();
    await p.setStringList(_k, raw);
  }
}
