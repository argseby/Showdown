import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'link_opener.dart';
import 'rest_client.dart';

final restClientProvider = Provider<RestClient>((ref) => RestClient());

/// The build the API reports, for the start screen's footer. Null while it
/// loads, and after a failure.
final serverVersionProvider = FutureProvider<String?>(
  (ref) => ref.read(restClientProvider).serverVersion(),
);

/// Whether this instance offers player profiles. False everywhere by
/// default, and then nothing about sign-in is shown.
final accountsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.read(restClientProvider).accountsEnabled(),
);

/// Opens external links (the project page in the footer) in a new tab.
final linkOpenerProvider = Provider<LinkOpener>((ref) => LinkOpener.create());

/// The table the viewer has just joined from the join page, so the play
/// page shows the table rules once; null after that and after a reload.
class JustJoinedNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void mark(String tableId) => state = tableId;

  void clear() => state = null;
}

final justJoinedProvider = NotifierProvider<JustJoinedNotifier, String?>(
  JustJoinedNotifier.new,
);
