import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 보안 저장소에 AES 키를 저장/조회하는 헬퍼
///
/// 앱 백업/암호화 용도의 32바이트 AES 키를 안전하게 관리합니다.
class CryptoKeys {
  CryptoKeys._internal();
  static final CryptoKeys _instance = CryptoKeys._internal();
  static CryptoKeys get instance => _instance;

  static const _aesAlias = 'backup_aes_key_v1';
  static const _storage = FlutterSecureStorage();

  /// 영구 저장소에서 AES 키를 조회하고, 없으면 생성하여 저장합니다.
  ///
  /// 반환값은 32바이트 길이의 키 바이트 배열입니다.
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
