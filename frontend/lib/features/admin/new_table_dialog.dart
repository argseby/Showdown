import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/admin_api.dart';
import '../../core/rest_client.dart';
import 'admin_session.dart';
import 'admin_widgets.dart';
import 'settings_form.dart';
import 'settings_form_model.dart';

/// Full-screen dialog with the full settings form. Creating a table makes the
/// caller its admin; the result carries the admin token, which is shown only
/// once.
Future<CreatedTable?> showNewTableDialog(BuildContext context) {
  // Pushed directly: [DialogConfiguration] does not forward its fullScreen
  // flag to the route, which would keep an inset around the dialog.
  return Navigator.of(context).push(
    DialogRoute<CreatedTable>(
      context: context,
      builder: (context) => const _NewTableDialog(),
      fullScreen: true,
      alignment: Alignment.center,
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          buildShadcnDialogTransitions(
            context,
            BorderRadius.zero,
            Alignment.center,
            animation,
            secondaryAnimation,
            true,
            child,
          ),
    ),
  );
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
      if (mounted) Navigator.of(context).pop(created);
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
    final theme = Theme.of(context);
    final gap = theme.density.baseGap * theme.scaling;
    final inset = theme.density.baseContainerPadding * theme.scaling;
    // Same surface as [AlertDialog], laid out by hand: the form takes the
    // whole width and the space between title and buttons, and scrolls
    // (without a scrollbar) only when the screen is too short for it.
    return ModalBackdrop(
      barrierColor: Colors.black.withValues(alpha: 0.8),
      surfaceClip: ModalBackdrop.shouldClipSurface(theme.surfaceOpacity),
      child: ModalContainer(
        filled: true,
        fillColor: theme.colorScheme.popover,
        borderRadius: BorderRadius.zero,
        borderWidth: 0,
        padding: EdgeInsets.all(inset),
        surfaceBlur: theme.surfaceBlur,
        surfaceOpacity: theme.surfaceOpacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminNewTable).large().semiBold(),
            Gap(gap * 2),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: SettingsForm(
                    state: _state,
                    errors: _errors,
                    serverErrors: _serverErrors,
                    showName: true,
                    onChanged: (s) => setState(() => _state = s),
                  ).small().muted(),
                ),
              ),
            ),
            Gap(gap * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlineButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                Gap(gap),
                PrimaryButton(
                  key: const Key('admin-create'),
                  onPressed: _busy ? null : _create,
                  child: Text(l10n.adminCreate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
