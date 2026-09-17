import 'package:lottie/lottie.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'poker_stickers.dart';

/// Every sticker a player may show next to their seat, poker scenes first
/// (drawn in code, see poker_stickers.dart), then the emoji. Must match the
/// server's protocol.Stickers.
const stickerIds = <String>[...pokerStickerIds, ...emojiStickerIds];

/// The emoji stickers: Google's Noto Animated Emoji as Lottie files bundled
/// under assets/stickers (see the README there for the licence).
const emojiStickerIds = <String>[
  'poker_face',
  'cool',
  'smirk',
  'thinking',
  'eyebrow',
  'monocle',
  'eyes',
  'speechless',
  'zipper',
  'grimace',
  'sweat',
  'downcast',
  'sob',
  'angry',
  'mind_blown',
  'scream',
  'giggle',
  'joy',
  'rofl',
  'sleeping',
  'drooling',
  'money_face',
  'star_struck',
  'party_face',
  'pleading',
  'eye_roll',
  'clown',
  'skull',
  'cold',
  'hot',
  'fire',
  'hundred',
  'party_popper',
  'money_wings',
  'clover',
  'fingers_crossed',
  'thumbs_up',
  'thumbs_down',
  'clap',
  'pray',
  'flex',
  'trophy',
];

/// Asset path of a sticker.
String stickerAsset(String id) => 'assets/stickers/$id.json';

/// One animated sticker, [size] square, looping.
class StickerView extends StatelessWidget {
  const StickerView({super.key, required this.id, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (pokerStickerIds.contains(id)) {
      return PokerSticker(
        key: ValueKey('sticker-view-$id'),
        id: id,
        size: size,
      );
    }
    return SizedBox(
      key: ValueKey('sticker-view-$id'),
      width: size,
      height: size,
      child: Lottie.asset(
        stickerAsset(id),
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        // An id this client does not ship (a newer server): show nothing.
        errorBuilder: (context, error, stack) => const SizedBox(),
      ),
    );
  }
}

/// A grid of every sticker; tapping one reports its id.
class StickerPicker extends StatelessWidget {
  const StickerPicker({super.key, required this.onSelected, this.size = 44});

  final ValueChanged<String> onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final id in stickerIds)
          GhostButton(
            key: Key('sticker-$id'),
            density: ButtonDensity.compact,
            onPressed: () => onSelected(id),
            child: StickerView(id: id, size: size),
          ),
      ],
    );
  }
}
