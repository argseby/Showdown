import 'dart:ui' show ViewFocusDirection, ViewFocusState;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'app/app.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // flutter/flutter#187939: on web the engine answers the framework's first
  // focus request synchronously, and focus traversal then measures widgets
  // before the first layout ("RenderBox was not laid out" at startup).
  // Focusing the view up front leaves nothing to bounce back.
  final view = binding.platformDispatcher.implicitView;
  if (kIsWeb && view != null) {
    binding.platformDispatcher.requestViewFocusChange(
      viewId: view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    );
  }
  usePathUrlStrategy();
  runApp(const ProviderScope(child: ShowdownApp()));
}
