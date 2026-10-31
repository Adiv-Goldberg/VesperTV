import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/l10n/de.dart';
import 'package:nox_iptv/l10n/fr.dart';
import 'package:nox_iptv/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('German covers every French key', () {
    expect(kFr.keys.where((k) => !kDe.containsKey(k)), isEmpty);
  });

  test('German keeps every {placeholder} of its English key', () {
    final re = RegExp(r'\{[a-zA-Z0-9_]+\}');
    for (final e in kDe.entries) {
      final want = re.allMatches(e.key).map((m) => m[0]).toList()..sort();
      final got = re.allMatches(e.value).map((m) => m[0]).toList()..sort();
      expect(got, want, reason: e.key);
    }
  });

  test('picking German translates the UI and score statuses', () async {
    await L10n.apply('de');
    expect(L10n.code, 'de');
    expect(tr('Settings'), 'Einstellungen');
    expect(tr('Season {season}', {'season': 2}), 'Staffel 2');
    expect(trSports('Final'), 'Endstand');
    expect(trSports('2OT'), '2. Verl.');
    await L10n.apply('en');
  });
}
