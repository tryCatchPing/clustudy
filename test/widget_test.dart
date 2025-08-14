// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_contest/main.dart';
import 'package:it_contest/features/db/isar_db.dart';

void main() {
  testWidgets('App renders router shell', (WidgetTester tester) async {
    // Use a temporary directory for Isar to avoid host-dependent paths during tests
    IsarDb.setTestDirectoryOverride(Directory.systemTemp.createTempSync('itc_test_').path);
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    // Basic smoke: app builds without throwing and has a MaterialApp Router widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
