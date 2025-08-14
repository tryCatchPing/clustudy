import 'dart:math';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoKeyService {
  CryptoKeyService._();
  static final CryptoKeyService instance = CryptoKeyService._();

  static const _keyAlias = 'isar_encryption_key_v1';
  static const _storage = FlutterSecureStorage();

  Future<List<int>?> loadKey() async {
    final base64 = await _storage.read(key: _keyAlias);
    if (base64 == null) return null;
    return _decode(base64);
  }

  Future<List<int>> getOrCreateKey() async {
    final existing = await loadKey();
    if (existing != null) return existing;
    final bytes = _randomBytes(32);
    await _storage.write(key: _keyAlias, value: _encode(bytes));
    return bytes;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _encode(List<int> bytes) => base64Encode(bytes);
  List<int> _decode(String s) => base64Decode(s);
}


