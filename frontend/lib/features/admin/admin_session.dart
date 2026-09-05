import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_api.dart';
import '../../core/providers.dart';

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(restClientProvider)),
);
