import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/watch_game_offer.dart';

/// The white "Watch game" pill above the player bar (Settings > Sports Trak
/// > Watch game button): a reminded game just started. Same look and remote
/// model as `SkipSegmentButton`: Up from the player bar focuses it (above
/// the skip pill when both show), OK switches, Down goes back. It never
/// switches by itself. Always returns a `Positioned` (it sits straight in
/// the player's Stack).
class WatchGameButton extends StatelessWidget {
  const WatchGameButton({
    super.key,
    required this.offer,
    required this.bottom,
    required this.showUpHint,
    required this.onWatch,
    required this.focusNode,
    this.onDown,
  });

  /// Null = hidden.
  final WatchGameOffer? offer;
  final double bottom;

  /// The player bar has the focus: the pill shows ▲ (Up reaches it).
  final bool showUpHint;
  final ValueChanged<WatchGameOffer> onWatch;
  final FocusNode focusNode;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    final offer = this.offer;
    if (offer == null) {
      return Positioned(
          right: 24,
          bottom: bottom,
          width: 0,
          height: 0,
          child: const SizedBox.shrink());
    }
    return Positioned(
      right: 24,
      bottom: bottom,
      child: Focus(
        focusNode: focusNode,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter) {
            if (event is KeyDownEvent) onWatch(offer);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowDown) {
            if (event is KeyDownEvent) onDown?.call();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return _pill(offer, focused);
        }),
      ),
    );
  }

  /// Floating glass (owner, +546): see-through dark blur, a soft shadow and
  /// a thin gold rim; gold and a little bigger when focused.
  Widget _pill(WatchGameOffer offer, bool focused) {
    const gold = Color(0xFFD4AF37);
    final hint = focused || showUpHint;
    return AnimatedScale(
      scale: focused ? 1.08 : 1,
      duration: const Duration(milliseconds: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6)),
            if (focused)
              BoxShadow(color: gold.withValues(alpha: 0.35), blurRadius: 14),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.black.withValues(alpha: focused ? 0.62 : 0.48),
              shape: StadiumBorder(
                  side: BorderSide(
                      color: focused ? gold : gold.withValues(alpha: 0.45),
                      width: focused ? 2 : 1)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                canRequestFocus: false,
                onTap: () => onWatch(offer),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports,
                            color: focused ? gold : Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Watch game'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              Text(offer.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (hint) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: focused
                                ? Text(tr('OK'),
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600))
                                : const Icon(Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white70, size: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
