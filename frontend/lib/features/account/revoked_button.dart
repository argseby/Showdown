import 'package:revoked_sign_in/revoked_sign_in.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A Revoked-branded button for the one gesture `revoked_sign_in` does not
/// cover: connecting the vault. Drawn the way revoked publishes it — black
/// with white text and mark, 10px corners, the mark 18px with a 10px gap —
/// with the package's own mark, so there is one drawing of it. One button
/// covers a light and a dark page, so it does not follow our theme.
class RevokedButton extends StatelessWidget {
  const RevokedButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: onPressed == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RevokedMark(size: 18, color: white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: white,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
