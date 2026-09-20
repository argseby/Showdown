import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// What the table rules page has typed but not settled yet, published so
/// the panel's title row can offer the tick and the cross there — at the
/// top, where they cannot scroll away from a long form.
class TableRulesPending {
  const TableRulesPending({
    this.fields = const {},
    this.applyAll,
    this.discardAll,
    this.busy = false,
  });

  /// The fields waiting for an answer.
  final Set<String> fields;

  /// Settles all of them, in the order they are listed.
  final Future<void> Function()? applyAll;

  /// Puts all of them back to what the server says.
  final void Function()? discardAll;

  /// True while a change is on its way to the server.
  final bool busy;

  bool get any => fields.isNotEmpty;
}

class TableRulesPendingNotifier extends Notifier<TableRulesPending> {
  @override
  TableRulesPending build() => const TableRulesPending();

  void set(TableRulesPending pending) {
    if (!ref.mounted) return;
    state = pending;
  }

  /// The page is gone (closed, or another page opened): nothing is
  /// waiting, so the title row shows nothing. It is told a beat after the
  /// page comes down, by which time the whole container may be gone — a
  /// closing app has nobody left to tell.
  void clear() {
    if (!ref.mounted) return;
    state = const TableRulesPending();
  }
}

final tableRulesPendingProvider =
    NotifierProvider<TableRulesPendingNotifier, TableRulesPending>(
      TableRulesPendingNotifier.new,
    );

/// The tick and the cross for everything still typed, for the panel's
/// title row. Nothing at all while nothing is waiting.
class TableRulesPendingActions extends ConsumerWidget {
  const TableRulesPendingActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(tableRulesPendingProvider);
    if (!pending.any) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${pending.fields.length}').muted().xSmall(),
        const Gap(4),
        IconButton.primary(
          key: const Key('rules-apply-all'),
          density: ButtonDensity.icon,
          icon: const Icon(LucideIcons.check, size: 15),
          onPressed: pending.busy ? null : () => pending.applyAll?.call(),
        ),
        const Gap(4),
        IconButton.outline(
          key: const Key('rules-discard-all'),
          density: ButtonDensity.icon,
          icon: const Icon(LucideIcons.x, size: 15),
          onPressed: pending.busy ? null : () => pending.discardAll?.call(),
        ),
      ],
    );
  }
}
