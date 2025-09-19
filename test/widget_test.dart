// test/link_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/design_system/components/organisms/link_dialog.dart';

void main() {
  testWidgets('리스트 아이템 탭하면 해당 텍스트 반환', (tester) async {
  String? result;

  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showLinkDialog(
                context,
                noteTitles: ['a', '루트'],
              );
            },
            child: const Text('open'),
          ),
        ),
      );
    }),
  ));

  // 다이얼로그 열기
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // 리스트 항목 선택
  await tester.tap(find.text('루트'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // 이제 result 값이 세팅됨
  expect(result, equals('루트'));
});
}
