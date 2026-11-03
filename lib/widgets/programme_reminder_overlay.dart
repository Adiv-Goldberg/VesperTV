import 'popup_surface.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../services/programme_reminders.dart';
import '../services/viewer_profile_service.dart';
import '../utils/refined_finish.dart';
import '../utils/time_format.dart';

/// Above routes, with no focus capture or automatic tuning. Foreground only.
class ProgrammeReminderOverlay extends StatefulWidget {
  const ProgrammeReminderOverlay({super.key});
  @override
  State<ProgrammeReminderOverlay> createState() =>
      _ProgrammeReminderOverlayState();
}

class _ProgrammeReminderOverlayState extends State<ProgrammeReminderOverlay>
    with WidgetsBindingObserver {
  ProgrammeReminders? _service;
  final _queue = <ProgrammeNotice>[];
  ProgrammeNotice? _notice;
  String? _viewer;
  Timer? _alarm, _hide;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _active = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<ProgrammeReminders>();
    final viewer = context.watch<ViewerProfileService>().active.id;
    if (_service == service && _viewer == viewer) return;
    _service?.removeListener(_refresh);
    _service = service;
    _viewer = viewer;
    _alarm?.cancel();
    _hide?.cancel();
    _queue.clear();
    _notice = null;
    service.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _refresh() {
    _alarm?.cancel();
    if (!mounted || !_active) return;
    final service = _service!;
    service.loadViewer();
    if (service.viewerId != _viewer) return;
    _queue.addAll(service.poll());
    if (_notice == null || !service.isCurrent(_notice!.reminder)) _next();
    final deadline = service.nextDeadline;
    if (deadline != null) {
      final delay = deadline.difference(service.now());
      _alarm = Timer(delay.isNegative ? Duration.zero : delay, _refresh);
    }
  }

  void _next() {
    _hide?.cancel();
    ProgrammeNotice? next;
    while (_queue.isNotEmpty) {
      final candidate = _queue.removeAt(0);
      if (_service!.isCurrent(candidate.reminder) &&
          candidate.validAt(_service!.now())) {
        next = candidate;
        break;
      }
    }
    setState(() => _notice = next);
    if (next != null) _hide = Timer(const Duration(seconds: 12), _next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _alarm?.cancel();
    _hide?.cancel();
    _queue.clear();
    setState(() => _notice = null);
    if (_active) _refresh();
  }

  @override
  void dispose() {
    _alarm?.cancel();
    _hide?.cancel();
    _service?.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (notice == null || _service?.viewerId != _viewer) {
      return const SizedBox.shrink();
    }
    final reminder = notice.reminder;
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
        child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Material(
                      color: transparentPopups(context)
                          ? Colors.transparent
                          : RefinedFinish.surface(
                              context, const Color(0xFA15171C)),
                      elevation: transparentPopups(context) ? 0 : 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PopupTextShadow(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                Icon(Icons.notifications_active, color: accent),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          notice.atStart
                                              ? tr('On now')
                                              : tr('Starts in 5 minutes'),
                                          style: TextStyle(color: accent)),
                                      const SizedBox(height: 6),
                                      Text(reminder.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17)),
                                      Text(
                                          '${reminder.channelName} · ${TimeFormat.hm.format(reminder.start.toLocal())}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ])),
                                ExcludeFocus(
                                    child: Semantics(
                                        label: tr('Close'),
                                        button: true,
                                        child: IconButton(
                                            onPressed: _next,
                                            icon: Icon(Icons.close,
                                                semanticLabel: tr('Close'))))),
                              ]))),
                    )))));
  }
}
