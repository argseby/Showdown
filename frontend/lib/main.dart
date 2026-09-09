import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'app/app.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: ShowdownApp()));
}
