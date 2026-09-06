import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/voice/voice_controller.dart';

/// Microphone settings: join or leave the voice chat and mute the mic.
Future<void> showMicDialog(BuildContext context, String tableId) {
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => _MicDialog(tableId: tableId),
  ).future;
}

class _MicDialog extends ConsumerWidget {
  const _MicDialog({required this.tableId});
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final voice = ref.watch(voiceControllerProvider(tableId));
    final ctrl = ref.read(voiceControllerProvider(tableId).notifier);
    final status = !voice.enabled
        ? l10n.micStateOff
        : voice.muted
        ? l10n.micStateMuted
        : l10n.micStateOn;
    Widget row(
      String label,
      IconData icon,
      bool value,
      VoidCallback onTap, {
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
          const Gap(10),
          Expanded(child: Text(label)),
          Switch(key: key, value: value, onChanged: (_) => onTap()),
        ],
      ),
    );
    return AlertDialog(
      title: Text(l10n.micTitle),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  !voice.enabled
                      ? LucideIcons.micOff
                      : voice.muted
                      ? LucideIcons.micOff
                      : LucideIcons.mic,
                  size: 18,
                  color: !voice.enabled
                      ? theme.colorScheme.mutedForeground
                      : voice.muted
                      ? theme.colorScheme.destructive
                      : const Color(0xFF43A047),
                ),
                const Gap(8),
                Text(status, key: const Key('mic-status')).semiBold(),
              ],
            ),
            const Gap(4),
            Text(l10n.micHint).muted().small(),
            const Gap(8),
            row(
              voice.enabled ? l10n.voiceOn : l10n.voiceOff,
              LucideIcons.headphones,
              voice.enabled,
              () => voice.enabled ? ctrl.disable() : ctrl.enable(),
              key: const Key('mic-voice'),
            ),
            if (voice.enabled) ...[
              row(
                voice.muted ? l10n.voiceMicMuted : l10n.voiceMicOn,
                voice.muted ? LucideIcons.micOff : LucideIcons.mic,
                !voice.muted,
                ctrl.toggleMute,
                key: const Key('mic-mute'),
              ),
              row(
                voice.camera ? l10n.cameraOn : l10n.cameraOff,
                voice.camera ? LucideIcons.video : LucideIcons.videoOff,
                voice.camera,
                ctrl.toggleCamera,
                key: const Key('mic-camera'),
              ),
              Text(l10n.cameraHint).muted().small(),
              if (voice.cameraUnavailable)
                Text(
                  l10n.cameraUnavailable,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.destructive,
                  ),
                ),
            ],
            if (voice.unavailable)
              Text(
                l10n.voiceUnavailable,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.destructive,
                ),
              ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
