import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server clock offset in milliseconds: `server_ts - local_now`, updated on
/// every snapshot and pong. Countdowns use [serverNow].
class TimeSyncNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void update(int serverTs, {int? localNow}) {
    state = serverTs - (localNow ?? DateTime.now().millisecondsSinceEpoch);
  }

  int serverNow() => DateTime.now().millisecondsSinceEpoch + state;
}

final timeSyncProvider = NotifierProvider<TimeSyncNotifier, int>(
  TimeSyncNotifier.new,
);
