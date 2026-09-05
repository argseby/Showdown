import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../shared/top_bar.dart';
import 'l10n.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      headers: [
        TopBar(title: Text(l10n.appTitle)),
        const Divider(),
      ],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.notFoundTitle).h2(),
            const Gap(8),
            Text(l10n.notFoundBody).muted(),
            const Gap(24),
            PrimaryButton(
              onPressed: () => context.go('/'),
              leading: const Icon(LucideIcons.house),
              child: Text(l10n.notFoundHome),
            ),
          ],
        ),
      ),
    );
  }
}
