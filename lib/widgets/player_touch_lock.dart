import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Keeps the video mounted and playing while only the unlock button accepts
/// input. Wrap the player's gesture detectors, rather than placing a barrier
/// inside them: an ancestor detector can still receive absorbed child taps.
///
/// The unlock button fades out after a few seconds and comes back on any
/// touch (owner, 2026-11-02: the lock covered the picture). It stays on
/// with a screen reader, which can't find a hidden button.
class PlayerTouchLock extends StatefulWidget {
  const PlayerTouchLock({
    super.key,
    required this.locked,
    required this.onUnlock,
    required this.child,
  });

  final bool locked;
  final VoidCallback onUnlock;
  final Widget child;

  @override
  State<PlayerTouchLock> createState() => _PlayerTouchLockState();
}

class _PlayerTouchLockState extends State<PlayerTouchLock> {
  static const _visibleFor = Duration(seconds: 3);
  bool _shown = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    if (widget.locked) _reveal();
  }

  @override
  void didUpdateWidget(PlayerTouchLock old) {
    super.didUpdateWidget(old);
    if (widget.locked && !old.locked) _reveal();
  }

  void _reveal() {
    _hide?.cancel();
    if (!_shown) setState(() => _shown = true);
    _hide = Timer(_visibleFor, () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;
    final visible = _shown || MediaQuery.of(context).accessibleNavigation;
    return PopScope(
      canPop: !locked,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ExcludeFocus(
              excluding: locked,
              child: AbsorbPointer(absorbing: locked, child: widget.child),
            ),
          ),
          if (locked) ...[
            // Any touch on the locked screen brings the button back.
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _reveal(),
              ),
            ),
            Positioned.fill(
              child: BlockSemantics(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: IgnorePointer(
                        ignoring: !visible,
                        child: AnimatedOpacity(
                          opacity: visible ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Semantics(
                            label: tr('Touch controls locked'),
                            child: Material(
                              color: Colors.black87,
                              shape: const CircleBorder(
                                  side: BorderSide(color: Colors.white38)),
                              child: IconButton(
                                key: const ValueKey('player-touch-unlock'),
                                tooltip: tr('Unlock touch controls'),
                                constraints: const BoxConstraints.tightFor(
                                    width: 56, height: 56),
                                icon: const Icon(Icons.lock,
                                    color: Colors.white, size: 26),
                                onPressed: widget.onUnlock,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
