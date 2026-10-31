import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/app_preferences.dart';
import '../../widgets/settings_scaffold.dart';

/// Settings > Device & data > Discord: a QR code to the community invite,
/// same shape as `SupportScreen`. Keep [url] in sync with the site/README
/// invite when it changes.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const url = 'https://discord.gg/VPQ849NPV';

  @override
  Widget build(BuildContext context) {
    final tv = context.read<AppPreferences>().isTelevision;
    return SettingsScaffold(
      title: tr('Discord'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr(
              'Questions, help with setup, feature ideas and release news: join the VesperTV community on Discord.')),
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
                  const SelectableText('discord.gg/VPQ849NPV',
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
        ],
      ),
    );
  }
}
