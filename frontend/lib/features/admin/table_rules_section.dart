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
import 'table_rules_pending.dart';

/// The host's table rules (blinds, times, rebuys, ...) as a section of the
/// Settings tab, so that everything a player can change lives in one place.
///
/// Every change settles on its own: a switch or a choice the moment it is
/// made, a typed value on the tick beside it. There is no save button for
/// the lot — one was there, and nobody could tell what it still held.
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

  /// Held from initState: a widget on its way out may not reach for ref.
  late final TableRulesPendingNotifier _pending;

  @override
  void dispose() {
    // The page is gone, so the title row has nothing to offer — but a
    // provider may not be written to while the tree is being taken down,
    // so the word goes out a beat later.
    final pending = _pending;
    Future.microtask(pending.clear);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pending = ref.read(tableRulesPendingProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// The server rejected the key: drop it so the section disappears.
  Future<void> _rejected() async {
    await ref.read(adminTokenProvider(widget.tableId).notifier).clear();
    if (mounted) showAdminToast(context, context.l10n.adminKeyRejected);
  }

  /// Tells the panel's title row what is still typed, so the tick and the
  /// cross up there can settle or drop the lot.
  void _publish() {
    final form = _form;
    final pending = form == null
        ? const <String>{}
        : form.toPatch().keys.toSet();
    _pending.set(
      TableRulesPending(
        fields: pending,
        busy: _saving,
        applyAll: pending.isEmpty ? null : _applyAll,
        discardAll: pending.isEmpty ? null : _discardAll,
      ),
    );
  }

  /// Settles every typed field, one after the other. The first one the
  /// server refuses stops the rest: the reason is shown under its field.
  Future<void> _applyAll() async {
    final form = _form;
    if (form == null) return;
    for (final field in form.toPatch().keys.toList()) {
      final current = _form;
      if (current == null || !current.toPatch().containsKey(field)) continue;
      await _apply(current, field);
      if (_errors.isNotEmpty || _serverErrors.isNotEmpty) return;
    }
  }

  /// Puts every typed field back to what the server says.
  void _discardAll() {
    final detail = _detail;
    if (detail == null) return;
    setState(() {
      _form = SettingsFormState.fromSettings(detail.settings);
      _errors = const {};
      _serverErrors = const {};
    });
    _publish();
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
      _publish();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 404) {
        setState(() => _gone = true);
      } else if (e.status == 401) {
        await _rejected();
      }
    }
  }

  /// Sends one field. The rest of the form is left alone, so a half-typed
  /// blind next door cannot ride along with a switch.
  Future<void> _apply(SettingsFormState next, String field) async {
    final detail = _detail;
    if (detail == null || _saving) return;
    final l10n = context.l10n;
    final errors = next.validate(seated: detail.players.length);
    setState(() {
      _form = next;
      _errors = {
        for (final e in errors.entries)
          if (e.key == field) e.key: e.value,
      };
      _serverErrors = const {};
    });
    if (_errors.isNotEmpty) return;
    final whole = next.toPatch();
    if (!whole.containsKey(field)) return;
    final patch = {field: whole[field]};
    setState(() => _saving = true);
    _publish();
    try {
      final result = await ref
          .read(adminApiProvider)
          .patchSettings(widget.token, widget.tableId, patch);
      if (!mounted) return;
      // Whatever else was typed stays typed: only this field goes back to
      // what the server now says.
      setState(() {
        final server = SettingsFormState.fromSettings(result.settings);
        _form = _form?.adopt(server, field) ?? server;
      });
      // A change that waits for the next hand says so; one that is already
      // in force needs no announcement, the control shows it.
      if (result.appliesNextHand.isNotEmpty) {
        showAdminToast(
          context,
          l10n.adminSavedNextHand(result.appliesNextHand.join(', ')),
        );
      }
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
      if (mounted) {
        setState(() => _saving = false);
        _publish();
      }
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
    // A tournament that has dealt in this round locks the money and
    // information settings; a new round unlocks them until its first deal.
    final locked = detail.tournamentLocked;
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
        SettingsForm(
          state: form,
          errors: _errors,
          serverErrors: _serverErrors,
          showPasswordKeepHint: true,
          seated: detail.players.length,
          locked: locked ? tournamentLockedFields : const {},
          onChanged: (s) {
            setState(() => _form = s);
            _publish();
          },
          onApply: _apply,
        ),
      ],
    );
  }
}
