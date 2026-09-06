import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/admin_api.dart';
import '../../core/rest_client.dart';
import 'admin_session.dart';
import 'admin_widgets.dart';
import 'settings_form.dart';
import 'settings_form_model.dart';

/// Dialog with the full settings form. Creating a table makes the caller its
/// admin; the result carries the admin token, which is shown only once.
Future<CreatedTable?> showNewTableDialog(BuildContext context) {
  return showOverlay<CreatedTable?>(
    context,
    const DialogConfiguration(),
    builder: (context) => const _NewTableDialog(),
  ).future;
}

class _NewTableDialog extends ConsumerStatefulWidget {
  const _NewTableDialog();

  @override
  ConsumerState<_NewTableDialog> createState() => _NewTableDialogState();
}

class _NewTableDialogState extends ConsumerState<_NewTableDialog> {
  SettingsFormState _state = SettingsFormState.fromSettings(
    AdminSettings.defaults,
  );
  Map<String, SettingsError> _errors = const {};
  Map<String, String> _serverErrors = const {};
  bool _busy = false;

  Future<void> _create() async {
    final errors = _state.validate(requireName: true);
    setState(() {
      _errors = errors;
      _serverErrors = const {};
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(adminApiProvider)
          .createTable(
            name: _state.name.trim(),
            settings: _state.toPatch(all: true),
          );
      if (mounted) {
        await closeOverlay<CreatedTable?>(context, created);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = {
          for (final f in e.fields) f.field: f.message,
          if (e.field != null && e.fields.isEmpty) e.field!: e.message,
        };
        if (_serverErrors.isEmpty) {
          showAdminToast(
            context,
            e.code == 'rate_limited'
                ? context.l10n.errRateLimited
                : context.l10n.errGeneric(e.message),
          );
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.adminNewTable),
      content: SingleChildScrollView(
        child: SettingsForm(
          state: _state,
          errors: _errors,
          serverErrors: _serverErrors,
          showName: true,
          onChanged: (s) => setState(() => _state = s),
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => closeOverlay<CreatedTable?>(context),
          child: Text(l10n.cancel),
        ),
        PrimaryButton(
          key: const Key('admin-create'),
          onPressed: _busy ? null : _create,
          child: Text(l10n.adminCreate),
        ),
      ],
    );
  }
}
