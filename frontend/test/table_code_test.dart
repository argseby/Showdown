import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/features/landing/table_code.dart';

void main() {
  group('TableCode.parse', () {
    test('accepts a bare code', () {
      expect(TableCode.parse('k7m2p9xq4w'), 'k7m2p9xq4w');
      expect(TableCode.parse('  K7M2P9XQ4W  '), 'k7m2p9xq4w');
    });

    test('extracts the id from links', () {
      expect(
        TableCode.parse('https://poker.example/t/k7m2p9xq4w'),
        'k7m2p9xq4w',
      );
      expect(
        TableCode.parse('http://localhost:8080/t/k7m2p9xq4w/play'),
        'k7m2p9xq4w',
      );
      expect(TableCode.parse('/t/k7m2p9xq4w?x=1'), 'k7m2p9xq4w');
    });

    test('rejects invalid input', () {
      expect(TableCode.parse(''), isNull);
      expect(TableCode.parse('short'), isNull);
      expect(TableCode.parse('k7m2p9xq4wz'), isNull);
      expect(
        TableCode.parse('k7m2p9xq01'),
        isNull,
      ); // 0 and 1 are not in the alphabet
      expect(TableCode.parse('https://poker.example/x/k7m2p9xq4w'), isNull);
    });
  });
}
