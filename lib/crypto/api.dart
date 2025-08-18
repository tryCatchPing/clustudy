import 'package:it_contest/crypto/keys.dart';

/// 고수준 암호화 API
///
/// 현재는 백업 키 발급만 노출합니다. 향후 키 회전 등 워크플로를 확장할 수 있습니다.
class CryptoApi {
  /// 앱 데이터 백업을 위한 AES-256 키를 반환합니다. 없으면 새로 생성합니다.
  static Future<List<int>> getOrCreateBackupKey() => CryptoKeys.instance.getOrCreateAesKey();
}
