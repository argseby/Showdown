import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/l10n.dart';
import '../app/preferences.dart';

/// Normal / Large / Extra large: scales cards, chips, buttons and text at
/// the table. Used on the join page and in the table drawer.
class DisplaySizePicker extends ConsumerWidget {
  const DisplaySizePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scale = ref.watch(uiScaleProvider);
    final labels = [
      l10n.displayNormal,
      l10n.displayLarge,
      l10n.displayExtraLarge,
    ];
    return Row(
      children: [
        for (var i = 0; i < UiScaleNotifier.options.length; i++) ...[
          if (i > 0) const Gap(6),
          Expanded(
            child:
                (scale == UiScaleNotifier.options[i]
                ? PrimaryButton.new
                : OutlineButton.new)(
                  key: Key('display-size-$i'),
                  size: ButtonSize.small,
                  onPressed: () => ref
                      .read(uiScaleProvider.notifier)
                      .set(UiScaleNotifier.options[i]),
                  child: Text(labels[i], textAlign: TextAlign.center),
                ),
          ),
        ],
      ],
    );
  }
}
