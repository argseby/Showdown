import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/config.dart';

void main() {
  test('deriveWsBase maps http(s) to ws(s)', () {
    expect(AppConfig.deriveWsBase(''), '');
    expect(
      AppConfig.deriveWsBase('http://localhost:8080'),
      'ws://localhost:8080',
    );
    expect(
      AppConfig.deriveWsBase('http://localhost:8080/'),
      'ws://localhost:8080',
    );
    expect(
      AppConfig.deriveWsBase('https://poker.example'),
      'wss://poker.example',
    );
  });
}
