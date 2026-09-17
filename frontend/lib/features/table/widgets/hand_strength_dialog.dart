import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/rest_client.dart';
import '../../../shared/playing_card.dart';

/// The beginner's readout: the own cards and the board, a meter of how
/// often the hand wins against random hands, a plain-language tier and a
/// tip. [load] fetches it from the server when the dialog opens.
Future<void> showHandStrengthDialog(
  BuildContext context, {
  required Future<HandStrengthDto> Function() load,
}) {
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => _StrengthDialog(dialog: dialog, load: load),
  ).future;
}

/// Holds the fetch so that rebuilds (every snapshot) do not repeat it; the
/// player can recalculate as the hand moves on.
class _StrengthDialog extends StatefulWidget {
  const _StrengthDialog({required this.dialog, required this.load});

  final BuildContext dialog;
  final Future<HandStrengthDto> Function() load;

  @override
  State<_StrengthDialog> createState() => _StrengthDialogState();
}

class _StrengthDialogState extends State<_StrengthDialog> {
  late Future<HandStrengthDto> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.strengthTitle),
      content: SizedBox(
        width: 340,
        child: FutureBuilder<HandStrengthDto>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              final e = snap.error;
              final gone = e is ApiException && e.code == 'invalid_state';
              return Text(
                gone ? l10n.strengthUnavailable : l10n.errGeneric('$e'),
                key: const Key('strength-error'),
              ).muted();
            }
            final data = snap.data;
            if (data == null) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return HandStrengthView(data: data);
          },
        ),
      ),
      actions: [
        OutlineButton(
          key: const Key('strength-refresh'),
          onPressed: () => setState(() {
            _future = widget.load();
          }),
          leading: const Icon(LucideIcons.refreshCw),
          child: Text(l10n.strengthRefresh),
        ),
        PrimaryButton(
          key: const Key('strength-close'),
          onPressed: () => closeOverlay<void>(widget.dialog),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// Colour of the meter at an equity ratio (0 = red, 1 = green).
Color strengthColor(double ratio) => Color.lerp(
  Color.lerp(
    const Color(0xFFE53935),
    const Color(0xFFFFB300),
    ratio.clamp(0.0, 0.5) * 2,
  )!,
  const Color(0xFF43A047),
  ((ratio - 0.5) * 2).clamp(0.0, 1.0),
)!;

class HandStrengthView extends StatelessWidget {
  const HandStrengthView({super.key, required this.data});

  final HandStrengthDto data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final percent = (data.equity * 100).round();
    // Where the marker sits: an even share among the players is the middle,
    // twice that share (or more) the right end.
    final share = 1 / (data.opponents + 1);
    final ratio = (data.equity / share / 2).clamp(0.0, 1.0);
    final color = strengthColor(ratio);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final c in data.cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: PlayingCardWidget(
                  card: c,
                  width: 40,
                  highlighted: data.best.contains(c),
                ),
              ),
            if (data.board.isNotEmpty) const Gap(14),
            for (final c in data.board)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: PlayingCardWidget(
                  card: c,
                  width: 30,
                  highlighted: data.best.contains(c),
                ),
              ),
          ],
        ),
        if (data.description.isNotEmpty) ...[
          const Gap(8),
          Text(data.description, textAlign: TextAlign.center).semiBold(),
        ],
        const Gap(14),
        // The meter: a red-to-green bar with the marker at the equity.
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 9,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE53935),
                          Color(0xFFFFB300),
                          Color(0xFF43A047),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (box.maxWidth - 26) * ratio,
                  top: 0,
                  child: Container(
                    key: const Key('strength-marker'),
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: theme.colorScheme.background,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.gauge,
                      size: 13,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(10),
        Text(
          l10n.strengthTier(data.tier),
          key: const Key('strength-tier'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const Gap(4),
        Text(
          l10n.strengthEquity(percent, data.opponents),
          key: const Key('strength-equity'),
          textAlign: TextAlign.center,
        ),
        const Gap(10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.lightbulb,
              size: 16,
              color: theme.colorScheme.mutedForeground,
            ),
            const Gap(8),
            Expanded(child: Text(l10n.strengthTip(data.tier))),
          ],
        ),
        const Gap(10),
        Text(l10n.strengthHint).muted().xSmall(),
      ],
    );
  }
}
