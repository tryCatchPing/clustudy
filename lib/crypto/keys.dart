import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoKeys {
  CryptoKeys._internal();
  static final CryptoKeys _instance = CryptoKeys._internal();
  static CryptoKeys get instance => _instance;

  static const _aesAlias = 'backup_aes_key_v1';
  static const _storage = FlutterSecureStorage();

  Future<List<int>> getOrCreateAesKey() async {
    final existing = await _storage.read(key: _aesAlias);
    if (existing != null) {
      return _decode(existing);
    }
    final key = _randomBytes(32);
    await _storage.write(key: _aesAlias, value: _encode(key));
    return key;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _encode(List<int> bytes) => base64Encode(bytes);
  List<int> _decode(String s) => base64Decode(s);
}
