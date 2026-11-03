import 'package:flutter/material.dart';

import '../services/desktop_live_recovery.dart';

/// Windows: "Reconnecting…" over a live video while [recovery] works on it
/// (nothing otherwise). Sits in the player's Stack.
class DesktopReconnectingBadge extends StatelessWidget {
  const DesktopReconnectingBadge({super.key, required this.recovery});

  final DesktopLiveRecovery recovery;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: recovery.status,
        builder: (context, text, _) => text == null
            ? const SizedBox.shrink()
            : Center(
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15)),
                      ),
                    ]),
                  ),
                ),
              ),
      );
}
