import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/admin_api.dart';
import '../../core/rest_client.dart';
import '../../core/session_store.dart';
import '../table/table_session.dart';
import 'admin_session.dart';
import 'admin_widgets.dart';
import 'settings_form.dart';
import 'settings_form_model.dart';

/// The host's table rules (blinds, times, rebuys, ...) as a section of the
/// Settings tab, so that everything a player can change lives in one place.
/// Loads the table with the admin token, shows the form with an
/// unsaved-changes bar and saves only what changed.
class TableRulesSection extends ConsumerStatefulWidget {
  const TableRulesSection({
    super.key,
    required this.tableId,
    required this.token,
  });

  final String tableId;
  final String token;

  @override
  ConsumerState<TableRulesSection> createState() => _TableRulesSectionState();
}

class _TableRulesSectionState extends ConsumerState<TableRulesSection> {
  AdminTableDetail? _detail;
  SettingsFormState? _form;
  Map<String, SettingsError> _errors = const {};
  Map<String, String> _serverErrors = const {};
  bool _saving = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// The server rejected the key: drop it so the section disappears.
  Future<void> _rejected() async {
    await ref.read(adminTokenProvider(widget.tableId).notifier).clear();
    if (mounted) showAdminToast(context, context.l10n.adminKeyRejected);
  }

  Future<void> _load() async {
    try {
      final detail = await ref
          .read(adminApiProvider)
          .getTable(widget.token, widget.tableId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        // Edits in progress stay; otherwise the form follows the server
        // (the blinds may have gone up underneath it).
        if (!(_form?.hasChanges ?? false)) {
          _form = SettingsFormState.fromSettings(detail.settings);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 404) {
        setState(() => _gone = true);
      } else if (e.status == 401) {
        await _rejected();
      }
    }
  }

  Future<void> _save() async {
    final form = _form;
    final detail = _detail;
    if (form == null || detail == null) return;
    final l10n = context.l10n;
    final errors = form.validate(seated: detail.players.length);
    setState(() {
      _errors = errors;
      _serverErrors = const {};
    });
    if (errors.isNotEmpty) return;
    final patch = form.toPatch();
    if (patch.isEmpty) {
      showAdminToast(context, l10n.adminNoChanges);
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(adminApiProvider)
          .patchSettings(widget.token, widget.tableId, patch);
      if (!mounted) return;
      setState(() => _form = SettingsFormState.fromSettings(result.settings));
      showAdminToast(
        context,
        result.appliesNextHand.isEmpty
            ? l10n.adminSaved
            : l10n.adminSavedNextHand(result.appliesNextHand.join(', ')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        await _rejected();
        return;
      }
      setState(() {
        _serverErrors = {
          for (final f in e.fields) f.field: f.message,
          if (e.fields.isEmpty && e.field != null) e.field!: e.message,
        };
      });
      if (_serverErrors.isEmpty) {
        showAdminToast(context, l10n.errGeneric(e.message));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Settings changed on the server (blinds up, another device): reload.
    ref.listen(
      tableSessionProvider(widget.tableId)
          .select((s) => s.snapshot?.table.settings),
      (prev, next) {
        if (prev != null && next != null && prev != next) _load();
      },
    );
    if (_gone) return const SizedBox.shrink();
    final detail = _detail;
    final form = _form;
    if (detail == null || form == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // A running tournament locks the money and information settings.
    final locked =
        detail.settings.tournament &&
        (detail.state != 'waiting' || detail.handNumber > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (locked)
          Padding(
            key: const Key('tournament-locked'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                const Gap(6),
                Expanded(
                  child: Text(l10n.tournamentLockedNote).muted().small(),
                ),
              ],
            ),
          ),
        // Unsaved changes are announced at the top, with Save right there.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: form.hasChanges
              ? Container(
                  key: const Key('admin-unsaved'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    border: Border.all(color: theme.colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.adminUnsavedChanges).semiBold().small(),
                      const Gap(8),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              key: const Key('admin-save'),
                              onPressed: _saving ? null : _save,
                              leading: const Icon(LucideIcons.save),
                              child: Text(l10n.adminSave),
                            ),
                          ),
                          const Gap(8),
                          OutlineButton(
                            key: const Key('admin-discard'),
                            onPressed: () => setState(() {
                              _form = SettingsFormState.fromSettings(
                                detail.settings,
                              );
                              _errors = const {};
                              _serverErrors = const {};
                            }),
                            child: Text(l10n.adminDiscard),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SettingsForm(
          state: form,
          errors: _errors,
          serverErrors: _serverErrors,
          showPasswordKeepHint: true,
          seated: detail.players.length,
          locked: locked ? tournamentLockedFields : const {},
          onChanged: (s) => setState(() => _form = s),
        ),
      ],
    );
  }
}
