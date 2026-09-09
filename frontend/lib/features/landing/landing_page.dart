import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/providers.dart';
import '../../core/session_store.dart';
import '../../shared/top_bar.dart';
import '../admin/new_table_dialog.dart';
import 'table_code.dart';

/// The project's public page, linked from the footer.
const projectUrl = 'https://github.com/argseby/Showdown';

/// The author credited in the footer, and their site.
const authorName = 'kiunke.dev';
const authorUrl = 'https://kiunke.dev';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final _controller = TextEditingController();
  final _codeFocus = FocusNode();
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    // EXPERIMENT: focus after the first frame instead of autofocus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

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
    _codeFocus.dispose();
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
                        focusNode: _codeFocus,
                        placeholder: Text(l10n.landingCodePlaceholder),
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
                const Gap(24),
                const _LandingFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The build the server reports, the project page and the author credit.
class _LandingFooter extends ConsumerWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final opener = ref.read(linkOpenerProvider);
    // The version is a nicety: while it loads, or when the API cannot be
    // reached, the rest of the footer still shows.
    final version = ref.watch(serverVersionProvider).value;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        if (version != null)
          Text(
            l10n.landingServerVersion(version),
            key: const Key('landing-version'),
          ).muted().small(),
        LinkButton(
          key: const Key('landing-source'),
          onPressed: () => opener.open(projectUrl),
          leading: const Icon(LucideIcons.github),
          size: ButtonSize.small,
          child: Text(l10n.landingSource),
        ),
        LinkButton(
          key: const Key('landing-author'),
          onPressed: () => opener.open(authorUrl),
          size: ButtonSize.small,
          child: Text(l10n.landingCreatedBy(authorName)),
        ),
      ],
    );
  }
}
