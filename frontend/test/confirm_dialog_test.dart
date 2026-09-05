import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/shared/confirm_dialog.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('confirm dialog resolves with the pressed button and closes', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => PrimaryButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Leave?',
                body: 'Sure?',
                confirmLabel: 'Leave',
                cancelLabel: 'Cancel',
                destructive: true,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Leave?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Leave?'), findsNothing);
    expect(
      find.text('open'),
      findsOneWidget,
      reason: 'the page below must survive',
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.text('Leave?'), findsNothing);
  });
}
