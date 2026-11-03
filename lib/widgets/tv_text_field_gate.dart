import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_preferences.dart';
import '../services/device_defaults.dart';

/// "Press OK to type" for a text field on a TV box (remote, no touch).
///
/// A plain `TextField` raises the system keyboard the moment it *gains*
/// focus, so D-pad focus could never pass over one: on a Fire Stick the
/// keyboard took over the remote as soon as focus landed, and Back closing
/// it cleared Flutter's focus (nothing focused, remote "stuck"); a TCL
/// Android TV keyboard came up unusable on the Search screen (user reports,
/// 2026-10-19). Here the field is `readOnly` (no input connection, no
/// keyboard) until OK/Select is pressed on it; leaving the field closes it
/// again. If the keyboard closing left nothing focused, focus goes back to
/// the field so the remote keeps working. Phones and Windows get the plain
/// field ([builder] with `readOnly: false`).
///
/// The [builder] must pass `readOnly` and [focusNode] to its `TextField`.
/// A [FocusNode] created and disposed with this widget, for a
/// [TvTextFieldGate] in a dialog or a picker that has no node of its own:
/// `FocusNodeOwner(builder: (_, node) => TvTextFieldGate(focusNode: node, …))`.
class FocusNodeOwner extends StatefulWidget {
  const FocusNodeOwner({super.key, required this.builder});

  final Widget Function(BuildContext context, FocusNode node) builder;

  @override
  State<FocusNodeOwner> createState() => _FocusNodeOwnerState();
}

class _FocusNodeOwnerState extends State<FocusNodeOwner> {
  final _node = FocusNode(debugLabel: 'gated-text-field');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _node);
}

class TvTextFieldGate extends StatefulWidget {
  const TvTextFieldGate({
    super.key,
    required this.focusNode,
    required this.builder,
  });

  final FocusNode focusNode;
  final Widget Function(BuildContext context, bool readOnly) builder;

  @override
  State<TvTextFieldGate> createState() => _TvTextFieldGateState();
}

class _TvTextFieldGateState extends State<TvTextFieldGate>
    with WidgetsBindingObserver {
  bool _typing = false;

  /// The keyboard took screen space while typing (it reports an inset).
  bool _keyboardShown = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
  }

  /// The keyboard closed (Back on it) while typing: back to read-only, so
  /// the input connection closes and the D-pad moves focus again. Google
  /// TV (Chromecast): with the connection left open, Gboard kept taking the
  /// arrows as cursor moves and the remote could not leave the field (user
  /// report, 1.0.51). Only when the keyboard reported an inset: Fire OS
  /// draws its own over the app and keeps its existing handling.
  @override
  void didChangeMetrics() {
    if (!_typing || !mounted) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    final inset = view.viewInsets.bottom;
    if (inset > 0) {
      _keyboardShown = true;
      return;
    }
    if (!_keyboardShown) return;
    _keyboardShown = false;
    setState(() => _typing = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = FocusManager.instance.primaryFocus;
      if (now == null || now is FocusScopeNode) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(TvTextFieldGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _rehide?.cancel();
    widget.focusNode.removeListener(_onFocus);
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The next field never opens its keyboard by itself, even after the
  /// keyboard's Next: Fire OS reports Back on its keyboard as that same
  /// Next, and keeping the keyboard up across fields made Back walk from
  /// field to field with the keyboard reopening each time (Fire Stick 4K
  /// Max, 2026-10-19). One more OK per field, never stuck.
  void _onFocus() {
    if (widget.focusNode.hasFocus || !_typing) return;
    _keyboardShown = false;
    setState(() => _typing = false);
    if (!_isFireOs) _hideAgainLater();
    // Fire OS: Back on its keyboard drops Flutter's focus altogether.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = FocusManager.instance.primaryFocus;
      if (now == null || now is FocusScopeNode) {
        widget.focusNode.requestFocus();
      }
    });
  }

  /// A raw handler, not a `Focus.onKeyEvent`: it runs before anything in
  /// the field's own subtree can claim the key.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !widget.focusNode.hasFocus) return false;
    if (!context.read<AppPreferences>().isTelevision) return false;
    final key = event.logicalKey;
    final ok = key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA;
    if (_typing) {
      final direction = _arrows[key];
      if (direction != null && !_isFireOs) {
        // An arrow only reaches the app when the keyboard isn't using it:
        // a visible keyboard takes the D-pad itself. So the keyboard is
        // closed and the field must give the remote back. Google TV
        // (Chromecast): Gboard reports no inset, so didChangeMetrics never
        // saw it close, and the open input connection turned the arrows
        // into cursor moves (user report, 1.0.52). Handled here, the key
        // never reaches the input connection. Not on Fire OS: its keyboard
        // sends its own selector moves to the app as arrows.
        _keyboardShown = false;
        setState(() => _typing = false);
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        _move(direction);
        _hideAgainLater();
        return true;
      }
      // Keyboard dismissed but the field kept focus (Formuler): OK raises
      // it again. Only the remote's own OK key: Fire OS turns Back on its
      // keyboard into a numpadEnter, which must not reopen it.
      if (!ok) return false;
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      return true;
    }
    if (!ok &&
        key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return false;
    }
    // readOnly -> false while focused opens the input connection and shows
    // the keyboard (EditableText.didUpdateWidget).
    setState(() => _typing = true);
    return true;
  }

  /// Google TV: Gboard could stay up after focus left the field (the hide
  /// came before the input connection closed) and keep the D-pad, so the
  /// remote looked stuck on Add Playlist's source list (owner, 2026-11-02,
  /// +568). Once the field is read-only and focus has moved, hide again.
  Timer? _rehide;

  void _hideAgainLater() {
    _rehide?.cancel();
    _rehide = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _typing) return;
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    });
  }

  static final _arrows = {
    LogicalKeyboardKey.arrowUp: TraversalDirection.up,
    LogicalKeyboardKey.arrowDown: TraversalDirection.down,
    LogicalKeyboardKey.arrowLeft: TraversalDirection.left,
    LogicalKeyboardKey.arrowRight: TraversalDirection.right,
  };

  static bool get _isFireOs =>
      DeviceDefaults.fingerprint.manufacturer.toLowerCase() == 'amazon';

  /// D-pad arrows on the field move focus, not the cursor. Once a field has
  /// a cursor (typed in once), EditableText's own arrow actions move it —
  /// Up/Down to the start/end of a one-line field, Left/Right a character —
  /// and consume the key even with the keyboard closed and the field
  /// read-only, and Flutter's fallback for arrows in a text field is "stay".
  /// So on screens without their own arrow handling the remote could not
  /// get past a search field it had typed in (the long-standing "stuck in
  /// the text field" report, 2026-10-21). While the keyboard is up it owns
  /// the D-pad, so this only acts once it's closed.
  ///
  /// A screen's own key handler (Add Playlist's field-to-field Up/Down) gets
  /// the key first, but Flutter still delivers it to the field afterwards.
  /// Its focus change is applied in a microtask queued before this one, so
  /// the move only happens when nothing else has moved focus already.
  void _move(TraversalDirection direction) => scheduleMicrotask(() {
        if (mounted && widget.focusNode.hasPrimaryFocus) {
          widget.focusNode.focusInDirection(direction);
        }
      });

  @override
  Widget build(BuildContext context) {
    if (!context.read<AppPreferences>().isTelevision) {
      return widget.builder(context, false);
    }
    return Actions(
      actions: {
        ExtendSelectionVerticallyToAdjacentLineIntent:
            CallbackAction<ExtendSelectionVerticallyToAdjacentLineIntent>(
          onInvoke: (i) => _move(
              i.forward ? TraversalDirection.down : TraversalDirection.up),
        ),
        ExtendSelectionByCharacterIntent:
            CallbackAction<ExtendSelectionByCharacterIntent>(
          onInvoke: (i) => _move(
              i.forward ? TraversalDirection.right : TraversalDirection.left),
        ),
      },
      child: widget.builder(context, !_typing),
    );
  }
}
