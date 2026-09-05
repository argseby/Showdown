import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rest_client.dart';

final restClientProvider = Provider<RestClient>((ref) => RestClient());
