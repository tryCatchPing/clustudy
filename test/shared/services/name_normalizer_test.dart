import 'package:clustudy/shared/services/name_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NameNormalizer.normalize', () {
    test('trims and collapses whitespace', () {
      final r = NameNormalizer.normalize('  Hello    World  ');
      expect(r, 'Hello World');
    });

    test('removes control and forbidden characters', () {
      final r = NameNormalizer.normalize('A:/\\*?"<>|\u0001B');
      expect(r, 'AB');
    });

    test('disallows reserved device names', () {
      expect(
        () => NameNormalizer.normalize('CON'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => NameNormalizer.normalize('nul.txt'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when becomes empty', () {
      expect(
        () => NameNormalizer.normalize('    \t\n '),
        throwsA(isA<FormatException>()),
      );
    });

    test('truncates to max length', () {
      final long = List.filled(200, 'a').join();
      final r = NameNormalizer.normalize(long, maxLength: 10);
      expect(r.length, 10);
    });
  });

  group('NameNormalizer.compareKey', () {
    test('case-insensitive equality', () {
      final a = NameNormalizer.compareKey('Hello  World');
      final b = NameNormalizer.compareKey('hello world');
      expect(a, b);
    });
  });
}
