import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 공통 테스트 설정 헬퍼
class TestHelper {
  static const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  static const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_all_the_time/flutter_secure_storage',
  );

  /// 테스트용 임시 디렉토리와 mock 설정
  static Future<TestEnvironment> setupTestEnvironment() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final tempRoot = await Directory.systemTemp.createTemp('it_contest_test_');
    final mockStorage = <String, String>{};

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempRoot.path;
        }
        return null;
      },
    );

    // Mock flutter_secure_storage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall call) async {
        if (call.method == 'read') {
          final key = call.arguments['key'] as String;
          return mockStorage[key];
        }
        if (call.method == 'write') {
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String;
          mockStorage[key] = value;
          return null;
        }
        if (call.method == 'delete') {
          final key = call.arguments['key'] as String;
          mockStorage.remove(key);
          return null;
        }
        if (call.method == 'readAll') {
          return Map<String, String>.from(mockStorage);
        }
        return null;
      },
    );

    return TestEnvironment(tempRoot, mockStorage);
  }

  /// 테스트 환경 정리
  static Future<void> cleanupTestEnvironment(TestEnvironment env) async {
    // 모든 mock 정리
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      null,
    );

    // 임시 디렉토리 삭제
    if (await env.tempRoot.exists()) {
      await env.tempRoot.delete(recursive: true);
    }
  }

  /// 테스트용 PDF 파일 생성
  static Future<File> createFakePdfFile(String path, int sizeBytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final content = List.generate(sizeBytes, (i) => i % 256);
    await file.writeAsBytes(content);
    return file;
  }

  /// 테스트 데이터 검증 헬퍼
  static void verifyTestDataIntegrity({
    required int expectedVaults,
    required int expectedFolders,
    required int expectedNotes,
    required int expectedPages,
    required int expectedLinks,
    required int expectedEdges,
    required Map<String, int> actualCounts,
  }) {
    expect(actualCounts['vaults'], expectedVaults, reason: 'Vault count mismatch');
    expect(actualCounts['folders'], expectedFolders, reason: 'Folder count mismatch');
    expect(actualCounts['notes'], expectedNotes, reason: 'Note count mismatch');
    expect(actualCounts['pages'], expectedPages, reason: 'Page count mismatch');
    expect(actualCounts['links'], expectedLinks, reason: 'Link count mismatch');
    expect(actualCounts['graphEdges'], expectedEdges, reason: 'Graph edge count mismatch');
  }
}

/// 테스트 환경 정보
class TestEnvironment {
  final Directory tempRoot;
  final Map<String, String> mockStorage;

  TestEnvironment(this.tempRoot, this.mockStorage);
}
