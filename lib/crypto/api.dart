import 'keys.dart';

class CryptoApi {
  // Expose key management flows for rotation in future
  static Future<List<int>> getOrCreateBackupKey() => CryptoKeys.instance.getOrCreateAesKey();
}


