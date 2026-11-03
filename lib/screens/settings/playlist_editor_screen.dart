import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/app_preferences.dart';
import '../../services/epg_service.dart';
import '../../services/playback_service.dart';
import '../../services/playlist_editor_server.dart';
import '../../services/playlist_manager.dart';
import '../../services/storage_service.dart';
import '../../widgets/settings_scaffold.dart';

/// Settings > Playlists & guide > Playlist editor: opens the local editor
/// page for a phone (QR) or a PC (address + code), plus the quick switches
/// that are easy with a remote. The server only runs while this screen is
/// open. See `dev-notes/iptv-editor-plan.md`.
class PlaylistEditorScreen extends StatefulWidget {
  const PlaylistEditorScreen({super.key});

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends State<PlaylistEditorScreen> {
  late final PlaylistEditorServer _server;
  String? _error;

  /// The QR code and address at the top aren't focusable, so D-pad focus
  /// coming back up to the first switch didn't scroll them back into view
  /// (owner, 2026-11-02). The first switch jumps the list to the top.
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final epg = context.read<EpgService>();
    _server = PlaylistEditorServer(context.read<PlaylistManager>(),
        context.read<PlaybackService>(), context.read<StorageService>())
      ..hasNoGuide =
          ((c) => epg.lastUpdated != null && !epg.hasPrograms(c.epgId))
      ..addListener(_changed);
    _server.start().catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _server.removeListener(_changed);
    _server.stop();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tv = context.read<AppPreferences>().isTelevision;
    final storage = context.read<StorageService>();
    final playlists = context.watch<PlaylistManager>();
    final address = _server.address;
    final qr = _server.qrUrl;
    const big = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
    return SettingsScaffold(
      title: tr('Playlist editor (Test flight)'),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr(
              'Rename channels, change logos, hide copies and dead streams, set fallback channels and clean up the guide, from your phone or PC. Your provider\'s playlist is never changed: edits are kept on this device and run again on every content update.')),
          const SizedBox(height: 16),
          if (_error != null)
            Text(tr('Could not open the editor: {e}', {'e': _error}))
          else if (address == null || qr == null)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 28,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(data: qr, size: 190),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Phone: scan the code.')),
                    const SizedBox(height: 10),
                    Text(tr('PC: open this address in a browser')),
                    SelectableText(address, style: big),
                    const SizedBox(height: 6),
                    Text(tr('and enter the code')),
                    SelectableText(_server.code,
                        style: big.copyWith(letterSpacing: 6)),
                    const SizedBox(height: 6),
                    Text(
                        tr('Same Wi-Fi or network as this device. The editor closes when you leave this screen.'),
                        style: Theme.of(context).textTheme.bodySmall),
                    if (!tv) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(qr),
                            mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(tr('Open in browser')),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          if (_server.lastChange != null) ...[
            const SizedBox(height: 12),
            Text(tr('Saved from your phone or PC: {name}',
                {'name': _server.lastChange})),
          ],
          if (_server.probing || _server.probeStopReason != null) ...[
            const SizedBox(height: 12),
            Text(_server.probing
                ? tr('Stream test {done}/{total}: {name}', {
                    'done': _server.probeDone + 1,
                    'total': _server.probeTotal,
                    'name': _server.probeCurrent ?? '',
                  })
                : tr('Stream test: {done}/{total} tested.', {
                    'done': _server.probeDone,
                    'total': _server.probeTotal,
                  })),
          ],
          const Divider(height: 32),
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (focused) {
              if (focused && _scroll.hasClients) _scroll.jumpTo(0);
            },
            child: SwitchListTile(
              autofocus: true,
              title: Text(tr('Switch to another copy when a channel fails')),
              subtitle: Text(tr(
                  'If a channel doesn\'t start or keeps dropping, play its next copy (FHD, then HD…) or your fallback channels, without an error screen.')),
              value: storage.getCopyFallback(),
              onChanged: (v) async {
                await storage.setCopyFallback(v);
                setState(() {});
              },
            ),
          ),
          for (final p in playlists.profiles)
            if (playlists.editorSession(p.id) case final s?) ...[
              const SizedBox(height: 8),
              Text(p.name, style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                title: Text(tr('Hide lower-quality copies')),
                subtitle: Text(tr(
                    'Only the best copy of each channel is listed; the others stay as automatic fallbacks.')),
                value: s.edits.hideLowerCopies,
                onChanged: (v) {
                  s.edits.hideLowerCopies = v;
                  s.saveEdits(s.edits);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: Text(tr('Hide separator rows')),
                subtitle: Text(tr('Rows like ##### SPORTS #####')),
                value: s.edits.hideSeparators,
                onChanged: (v) {
                  s.edits.hideSeparators = v;
                  s.saveEdits(s.edits);
                  setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                    tr('{n} channels hidden by the editor',
                        {'n': s.editHidden.length}),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
        ],
      ),
    );
  }
}
