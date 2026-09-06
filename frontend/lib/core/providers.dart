import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'link_opener.dart';
import 'rest_client.dart';

final restClientProvider = Provider<RestClient>((ref) => RestClient());

/// The build the API reports, for the start screen's footer. Null while it
/// loads, and after a failure.
final serverVersionProvider = FutureProvider<String?>(
  (ref) => ref.read(restClientProvider).serverVersion(),
);

/// Opens external links (the project page in the footer) in a new tab.
final linkOpenerProvider = Provider<LinkOpener>((ref) => LinkOpener.create());
