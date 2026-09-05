import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The UI is built with shadcn_flutter exclusively and must stay
/// platform-neutral. This guards the import rules from the project brief.
void main() {
  test('lib/ contains no Material, Cupertino or dart:html imports', () {
    const forbidden = [
      'package:flutter/material.dart',
      'package:flutter/cupertino.dart',
      'package:shadcn_flutter_material/',
      'dart:html',
    ];
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final import in forbidden) {
        if (source.contains("'$import") || source.contains('"$import')) {
          offenders.add('${entity.path}: $import');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
