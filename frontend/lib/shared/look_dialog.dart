import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/l10n.dart';
import 'avatars.dart';
import 'hats.dart';

/// The player's look: avatar and hat, both chosen in one dialog with two
/// tabs. Returns the pick on Done, null on Cancel.
Future<({int avatar, String? hat})?> showLookDialog(
  BuildContext context, {
  required int avatar,
  required String? hat,
}) {
  return showOverlay<({int avatar, String? hat})>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => _LookDialog(dialog: dialog, avatar: avatar, hat: hat),
  ).future;
}

class _LookDialog extends StatefulWidget {
  const _LookDialog({
    required this.dialog,
    required this.avatar,
    required this.hat,
  });

  final BuildContext dialog;
  final int avatar;
  final String? hat;

  @override
  State<_LookDialog> createState() => _LookDialogState();
}

class _LookDialogState extends State<_LookDialog> {
  late int _avatar = widget.avatar;
  late String? _hat = widget.hat;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The pick so far, with its hat.
          Padding(
            padding: const EdgeInsets.only(top: 40 * hatOverflow),
            child: PlayerAvatar(index: _avatar, size: 40, hat: _hat),
          ),
          const Gap(12),
          Text(l10n.joinAvatarChange),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tabs(
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
              children: [
                TabItem(
                  key: const Key('look-tab-avatar'),
                  child: Text(l10n.joinAvatarLabel),
                ),
                TabItem(
                  key: const Key('look-tab-hat'),
                  child: Text(l10n.hatTitle),
                ),
              ],
            ),
            const Gap(12),
            if (_tab == 0)
              AvatarPicker(
                selected: _avatar,
                size: 44,
                onSelected: (i) => setState(() => _avatar = i),
              )
            else
              HatPicker(
                selected: _hat,
                avatar: _avatar,
                size: 44,
                onSelected: (id) =>
                    setState(() => _hat = id == hatNone ? null : id),
              ),
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () =>
              closeOverlay<({int avatar, String? hat})>(widget.dialog),
          child: Text(l10n.cancel),
        ),
        PrimaryButton(
          key: const Key('look-done'),
          onPressed: () => closeOverlay<({int avatar, String? hat})>(
            widget.dialog,
            (avatar: _avatar, hat: _hat),
          ),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
