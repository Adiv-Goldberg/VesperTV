import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/app_preferences.dart';
import '../../widgets/settings_scaffold.dart';

/// Settings > General > Support VesperTV: a QR code to the site's support
/// page (`docs/support.html`), which holds the donation links so they can
/// change without an app update. Optional and quiet: no popups, nothing
/// locked (owner, 2026-10-30).
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const url = 'https://vespertv.app/support.html';

  @override
  Widget build(BuildContext context) {
    final tv = context.read<AppPreferences>().isTelevision;
    return SettingsScaffold(
      title: tr('Support VesperTV'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr(
              'VesperTV is free and always will be: no ads, no tracking, no paid features. The support page shows how you can help pay for the server, the website and development.')),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(data: url, size: 170),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Scan with your phone, or open')),
                  const SizedBox(height: 4),
                  const SelectableText('vespertv.app/support.html',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  if (!tv) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      autofocus: true,
                      onPressed: () => launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(tr('Open')),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            tr('Supporting is a thank-you, never a paywall: everyone gets the same app.'),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
