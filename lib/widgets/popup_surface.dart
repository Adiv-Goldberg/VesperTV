import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_preferences.dart';

/// Settings > Interface > Goals alert > "Transparent popups": reminder and
/// goal-alert cards drop their fill and keep only the logo and
/// text (no outline either). Text gets a soft shadow so it stays readable
/// over video.
bool transparentPopups(BuildContext context) =>
    context.watch<AppPreferences?>()?.transparentPopups ?? false;

class PopupTextShadow extends StatelessWidget {
  const PopupTextShadow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!transparentPopups(context)) return child;
    return DefaultTextStyle.merge(
      style: const TextStyle(shadows: [
        Shadow(color: Colors.black, blurRadius: 6),
        Shadow(color: Colors.black, blurRadius: 2),
      ]),
      child: child,
    );
  }
}
