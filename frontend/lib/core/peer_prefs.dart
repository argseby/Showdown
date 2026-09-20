import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the viewer chose for one other player: their voice volume or mute,
/// and whether their video, hat and win streak are shown. Only on this
/// device and only for this visit of the table; nothing is sent, the other
/// player does not notice.
class PeerPrefs {
  const PeerPrefs({
    this.volume = 1,
    this.muted = false,
    this.hideVideo = false,
    this.hideHat = false,
    this.hideHeat = false,
    this.hideStickers = false,
    this.hideDrawings = false,
  });

  static const none = PeerPrefs();

  /// Playback volume of their voice, 0..1 (the slider); [muted] wins.
  final double volume;
  final bool muted;
  final bool hideVideo;
  final bool hideHat;
  final bool hideHeat;
  final bool hideStickers;
  final bool hideDrawings;

  /// The volume to play them at.
  double get effectiveVolume => muted ? 0 : volume;

  /// Nothing changed from the defaults.
  bool get isDefault =>
      volume == 1 &&
      !muted &&
      !hideVideo &&
      !hideHat &&
      !hideHeat &&
      !hideStickers &&
      !hideDrawings;

  PeerPrefs copyWith({
    double? volume,
    bool? muted,
    bool? hideVideo,
    bool? hideHat,
    bool? hideHeat,
    bool? hideStickers,
    bool? hideDrawings,
  }) => PeerPrefs(
    volume: volume ?? this.volume,
    muted: muted ?? this.muted,
    hideVideo: hideVideo ?? this.hideVideo,
    hideHat: hideHat ?? this.hideHat,
    hideHeat: hideHeat ?? this.hideHeat,
    hideStickers: hideStickers ?? this.hideStickers,
    hideDrawings: hideDrawings ?? this.hideDrawings,
  );

  @override
  bool operator ==(Object other) =>
      other is PeerPrefs &&
      other.volume == volume &&
      other.muted == muted &&
      other.hideVideo == hideVideo &&
      other.hideHat == hideHat &&
      other.hideHeat == hideHeat &&
      other.hideStickers == hideStickers &&
      other.hideDrawings == hideDrawings;

  @override
  int get hashCode => Object.hash(
    volume,
    muted,
    hideVideo,
    hideHat,
    hideHeat,
    hideStickers,
    hideDrawings,
  );
}

/// Per-player choices by player id; entries at their defaults are dropped.
class PeerPrefsNotifier extends Notifier<Map<String, PeerPrefs>> {
  @override
  Map<String, PeerPrefs> build() => const {};

  PeerPrefs of(String playerId) => state[playerId] ?? PeerPrefs.none;

  void set(String playerId, PeerPrefs prefs) {
    final next = {...state};
    if (prefs.isDefault) {
      next.remove(playerId);
    } else {
      next[playerId] = prefs;
    }
    state = next;
  }

  void reset(String playerId) => set(playerId, PeerPrefs.none);

  /// Forgets everything (leaving the table). The table clears this as it
  /// goes away, which can land after the container itself is gone — a
  /// provider nobody is left to read needs no reset.
  void clear() {
    if (!ref.mounted) return;
    state = const {};
  }
}

final peerPrefsProvider =
    NotifierProvider<PeerPrefsNotifier, Map<String, PeerPrefs>>(
      PeerPrefsNotifier.new,
    );
