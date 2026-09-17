import 'dart:ui' as ui;

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

/// One sticker, [size] square, looping; [animate] false draws a still
/// frame (the picker shows every sticker at once, and animating them all
/// stalled the page in release builds).
class StickerView extends StatelessWidget {
  const StickerView({
    super.key,
    required this.id,
    required this.size,
    this.animate = true,
  });

  final String id;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (pokerStickerIds.contains(id)) {
      return PokerSticker(
        key: ValueKey('sticker-view-$id'),
        id: id,
        size: size,
        animate: animate,
      );
    }
    if (!animate) {
      // A still: rasterized once per id and size. Dozens of live vector
      // renderers in the picker made the page crawl.
      return _LottieStill(
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
        animate: animate,
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
            child: StickerView(id: id, size: size, animate: false),
          ),
      ],
    );
  }
}

/// One frame of a Lottie sticker as an image, rendered once and cached by
/// id and pixel size; the picker shows it instead of a live animation.
class _LottieStill extends StatefulWidget {
  const _LottieStill({super.key, required this.id, required this.size});

  final String id;
  final double size;

  /// The frame shown: the first, which is the emoji at rest (later frames
  /// catch faces mid-effect).
  static const stillProgress = 0.0;

  static final _cache = <String, Future<ui.Image>>{};

  static Future<ui.Image> render(String id, int px) =>
      _cache.putIfAbsent('$id@$px', () async {
        final composition = await AssetLottie(stickerAsset(id)).load();
        final drawable = LottieDrawable(composition)
          ..setProgress(stillProgress);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        drawable.draw(
          canvas,
          Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()),
          fit: BoxFit.contain,
        );
        return recorder.endRecording().toImage(px, px);
      });

  @override
  State<_LottieStill> createState() => _LottieStillState();
}

class _LottieStillState extends State<_LottieStill> {
  ui.Image? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final px = (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil();
    _LottieStill.render(widget.id, px)
        .then((img) {
          if (mounted) setState(() => _image = img);
        })
        .catchError((Object _) {
          // An id this client does not ship: stays blank.
        });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: image == null
          ? null
          : RawImage(image: image, width: widget.size, height: widget.size),
    );
  }
}
