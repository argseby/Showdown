import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/session_store.dart';
import '../../shared/top_bar.dart';
import '../admin/new_table_dialog.dart';
import 'table_code.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final _controller = TextEditingController();
  bool _invalid = false;

  /// Creates a table; the creator's admin key is stored on this device and
  /// the join page opens so the host can take a seat.
  Future<void> _create() async {
    final created = await showNewTableDialog(context);
    if (created == null || !mounted) return;
    final id = created.detail.id;
    await ref.read(adminTokenProvider(id).notifier).save(created.adminToken);
    if (mounted) context.go('/t/$id');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    final id = TableCode.parse(_controller.text);
    if (id == null) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    context.go('/t/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        TopBar(title: Text(l10n.appTitle)),
        const Divider(),
      ],
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.appTitle).h1(),
                const Gap(8),
                Text(l10n.landingTagline).lead(),
                const Gap(32),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.landingCodeLabel).semiBold(),
                      const Gap(8),
                      TextField(
                        key: const Key('landing-code'),
                        controller: _controller,
                        placeholder: Text(l10n.landingCodePlaceholder),
                        autofocus: true,
                        onSubmitted: (_) => _open(),
                        onChanged: (_) {
                          if (_invalid) setState(() => _invalid = false);
                        },
                      ),
                      if (_invalid) ...[
                        const Gap(8),
                        Text(
                          l10n.landingInvalidCode,
                          key: const Key('landing-error'),
                          style: TextStyle(
                            color: theme.colorScheme.destructive,
                          ),
                        ).small(),
                      ],
                      const Gap(16),
                      PrimaryButton(
                        key: const Key('landing-open'),
                        onPressed: _open,
                        leading: const Icon(LucideIcons.arrowRight),
                        child: Text(l10n.landingJoin),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.landingCreateTitle).semiBold(),
                      const Gap(4),
                      Text(l10n.landingCreateHint).muted().small(),
                      const Gap(12),
                      OutlineButton(
                        key: const Key('landing-create'),
                        onPressed: _create,
                        leading: const Icon(LucideIcons.plus),
                        child: Text(l10n.landingCreate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
