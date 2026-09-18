import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

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
  'cursing',
  'broken_heart',
];

/// Asset path of a sticker.
String stickerAsset(String id) => 'assets/stickers/$id.json';

/// One sticker, [size] square, looping. In the picker ([preview]) an emoji
/// is a flipbook: its frames are rendered once into one image and played
/// back by drawing sub-rectangles, which allocates nothing per frame. A live
/// Lottie renderer creates hundreds of vector paths every frame, and in
/// the wasm build each one leaves a finalizer entry behind; with dozens of
/// them at once the JS heap filled up until a huge collection froze the
/// page for seconds. The one sticker shown over a seat still runs live.
class StickerView extends StatelessWidget {
  const StickerView({
    super.key,
    required this.id,
    required this.size,
    this.animate = true,
    this.preview = false,
  });

  final String id;
  final double size;
  final bool animate;

  /// A small preview in the picker (flipbook, throttled poker scenes).
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (pokerStickerIds.contains(id)) {
      if (preview) {
        return _CapturedScene(
          key: ValueKey('sticker-view-$id'),
          id: id,
          size: size,
        );
      }
      return PokerSticker(
        key: ValueKey('sticker-view-$id'),
        id: id,
        size: size,
        animate: animate,
      );
    }
    if (preview) {
      return _FlipbookSticker(
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

/// A rendered flipbook of one emoji: [frames] frames side by side in one
/// image, plus the loop length. Cached by id and pixel size for good.
class _Flipbook {
  const _Flipbook(this.sheet, this.px, this.period);

  final ui.Image sheet;
  final int px;
  final Duration period;

  static const frames = 16;
  static final _cache = <String, Future<_Flipbook>>{};

  static Future<_Flipbook> load(String id, int px) =>
      _cache.putIfAbsent('$id@$px', () async {
        final composition = await AssetLottie(stickerAsset(id)).load();
        final drawable = LottieDrawable(composition);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final side = px.toDouble();
        for (var i = 0; i < frames; i++) {
          drawable.setProgress(i / frames);
          canvas.save();
          canvas.translate(i * side, 0);
          canvas.clipRect(Rect.fromLTWH(0, 0, side, side));
          drawable.draw(
            canvas,
            Rect.fromLTWH(0, 0, side, side),
            fit: BoxFit.contain,
          );
          canvas.restore();
        }
        final sheet = await recorder.endRecording().toImage(px * frames, px);
        // The parsed composition is big and no longer needed: the sheet
        // is the preview, and the seat sticker reloads it when shown.
        Lottie.cache.clear();
        // Short loops play at their real pace; long ones are sped up so
        // 16 frames still move at 8 fps or better.
        final ms = composition.duration.inMilliseconds.clamp(800, 2000);
        return _Flipbook(sheet, px, Duration(milliseconds: ms));
      });
}

class _FlipbookSticker extends StatefulWidget {
  const _FlipbookSticker({super.key, required this.id, required this.size});

  final String id;
  final double size;

  @override
  State<_FlipbookSticker> createState() => _FlipbookStickerState();
}

class _FlipbookStickerState extends State<_FlipbookSticker>
    with SingleTickerProviderStateMixin {
  _Flipbook? _book;
  final _frame = ValueNotifier<int>(0);
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_book != null) return;
    // Phones with a 3x screen get 2x frames: plenty at this size and a
    // third less texture memory.
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    final px = (widget.size * dpr).ceil();
    _Flipbook.load(widget.id, px)
        .then((book) {
          if (!mounted) return;
          setState(() => _book = book);
          _ticker = createTicker((elapsed) {
            final f =
                (elapsed.inMilliseconds *
                    _Flipbook.frames ~/
                    book.period.inMilliseconds) %
                _Flipbook.frames;
            if (f != _frame.value) _frame.value = f;
          })..start();
        })
        .catchError((Object _) {
          // An id this client does not ship: stays blank.
        });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: book == null
          ? null
          : CustomPaint(painter: _FlipbookPainter(book, _frame)),
    );
  }
}

/// A poker scene in the picker: shown live while its frames are captured
/// off the screen, one per phase, then played back from the captured
/// images. A scene is a widget tree (transforms, opacity, text) that
/// allocates plenty on every rebuild; two dozen of them repainting at once
/// was the bulk of the churn that filled the JS heap.
class _CapturedScene extends StatefulWidget {
  const _CapturedScene({super.key, required this.id, required this.size});

  final String id;
  final double size;

  /// Frames per loop: 10 a second over the 2.6 s scene.
  static const frames = 26;

  /// Captured frames by id and pixel size, kept for good.
  static final _cache = <String, List<ui.Image>>{};

  @override
  State<_CapturedScene> createState() => _CapturedSceneState();
}

class _CapturedSceneState extends State<_CapturedScene>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  final _frame = ValueNotifier<int>(0);
  List<ui.Image>? _frames;
  bool _failed = false;
  int _retries = 0;
  var _captured = <ui.Image>[];
  int _phase = 0;
  bool _busy = false;
  Ticker? _ticker;
  double _dpr = 1;

  String get _key => '${widget.id}@${(widget.size * _dpr).ceil()}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    final done = _CapturedScene._cache[_key];
    if (done != null && _frames == null) _play(done);
  }

  void _play(List<ui.Image> frames) {
    setState(() => _frames = frames);
    _ticker = createTicker((elapsed) {
      final f =
          (elapsed.inMilliseconds *
              frames.length ~/
              PokerSceneFrame.loop.inMilliseconds) %
          frames.length;
      if (f != _frame.value) _frame.value = f;
    })..start();
  }

  /// After the frame with phase [_phase] painted, grab it and move on.
  void _captureAfterFrame() {
    if (_busy || _frames != null) return;
    _busy = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final boundary =
          _boundary.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || !mounted) {
        _busy = false;
        return;
      }
      try {
        _captured.add(await boundary.toImage(pixelRatio: _dpr));
      } catch (e) {
        // No painted layer yet: the dialog is still fading in (children
        // under zero opacity are not painted). Try again next frame; a
        // renderer that never manages stays live at a low rate instead.
        _busy = false;
        if (!mounted) return;
        if (++_retries > 300) {
          debugPrint('sticker capture ${widget.id} failed: $e');
          setState(() => _failed = true);
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
        WidgetsBinding.instance.scheduleFrame();
        return;
      }
      if (!mounted) return;
      _busy = false;
      if (_captured.length >= _CapturedScene.frames) {
        final frames = _captured;
        _captured = [];
        _CapturedScene._cache[_key] = frames;
        _play(frames);
      } else {
        setState(() => _phase = _captured.length);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = _frames;
    if (frames != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _FramesPainter(frames, _frame)),
      );
    }
    if (_failed) return PokerSticker(id: widget.id, size: widget.size, fps: 10);
    _captureAfterFrame();
    return RepaintBoundary(
      key: _boundary,
      child: PokerSceneFrame(
        id: widget.id,
        t: _phase / _CapturedScene.frames,
        size: widget.size,
      ),
    );
  }
}

class _FramesPainter extends CustomPainter {
  _FramesPainter(this.frames, this.frame) : super(repaint: frame);

  final List<ui.Image> frames;
  final ValueNotifier<int> frame;
  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final img = frames[frame.value % frames.length];
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Offset.zero & size,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_FramesPainter old) => old.frames != frames;
}

class _FlipbookPainter extends CustomPainter {
  _FlipbookPainter(this.book, this.frame) : super(repaint: frame);

  final _Flipbook book;
  final ValueNotifier<int> frame;
  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final px = book.px.toDouble();
    canvas.drawImageRect(
      book.sheet,
      Rect.fromLTWH(frame.value * px, 0, px, px),
      Offset.zero & size,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_FlipbookPainter old) => old.book != book;
}

/// A grid of every sticker; tapping one reports its id.
class StickerPicker extends StatelessWidget {
  const StickerPicker({
    super.key,
    required this.onSelected,
    this.size = 44,
    this.height = 300,
  });

  final ValueChanged<String> onSelected;
  final double size;

  /// The grid scrolls inside this height and builds only the rows on
  /// screen: with every sticker animating at once, weak devices (phones
  /// above all) ran out of breath and the browser killed the page.
  final double height;

  @override
  Widget build(BuildContext context) {
    final cell = size + 12;
    return SizedBox(
      height: height,
      // No scrollbar: it sat over the last column and looked like a slider.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: GridView.builder(
          key: const Key('sticker-grid'),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: cell,
            mainAxisExtent: cell,
          ),
          itemCount: stickerIds.length,
          itemBuilder: (context, i) {
            final id = stickerIds[i];
            return RepaintBoundary(
              child: GhostButton(
                key: Key('sticker-$id'),
                density: ButtonDensity.compact,
                onPressed: () => onSelected(id),
                child: StickerView(id: id, size: size, preview: true),
              ),
            );
          },
        ),
      ),
    );
  }
}
