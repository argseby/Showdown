import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/providers.dart';
import '../../core/session_store.dart';
import '../../shared/logo.dart';
import '../../shared/top_bar.dart';
import '../admin/new_table_dialog.dart';
import 'table_code.dart';

/// The project's public page, linked from the footer.
const projectUrl = 'https://github.com/argseby/Showdown';

/// The author credited in the footer, and their site.
const authorName = 'kiunke.dev';
const authorUrl = 'https://kiunke.dev';

/// Where the bundled stickers come from (attribution, CC BY 4.0).
const stickersUrl = 'https://googlefonts.github.io/noto-emoji-animation/';

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
        TopBar(leading: const [Logo()], title: Text(l10n.appTitle)),
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
                const Align(
                  alignment: Alignment.center,
                  child: Logo(height: 80),
                ),
                const Gap(16),
                Text(l10n.appTitle, textAlign: TextAlign.center).h1(),
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

    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.mutedForeground,
    );
    // Every item in the same quiet style, links underlined on hover only,
    // dots between them; the row wraps and stays centred on phones.
    Widget link(Key key, String label, String url, {IconData? icon}) =>
        GhostButton(
          key: key,
          size: ButtonSize.xSmall,
          density: ButtonDensity.compact,
          onPressed: () => opener.open(url),
          leading: icon == null
              ? null
              : Icon(icon, size: 12, color: theme.colorScheme.mutedForeground),
          child: Text(label, style: style),
        );
    final items = <Widget>[
      if (version != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            l10n.landingServerVersion(version),
            key: const Key('landing-version'),
            style: style,
          ),
        ),
      link(
        const Key('landing-source'),
        l10n.landingSource,
        projectUrl,
        icon: LucideIcons.github,
      ),
      link(
        const Key('landing-author'),
        l10n.landingCreatedBy(authorName),
        authorUrl,
      ),
      link(const Key('landing-stickers'), l10n.landingStickers, stickersUrl),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 2,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('·', style: style),
            ),
          items[i],
        ],
      ],
    );
  }
}
