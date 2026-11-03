import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/archive_models.dart';
import 'package:nox_iptv/services/archive_service.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An adult-style add-on: custom-type movies plus plain "series" shows.
/// Its shows used to land in the main TV Shows (user report, 2026-10-20);
/// the whole source now goes under Other, and the per-source switch moves
/// it either way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adult = ArchiveSource(
    manifestUrl: 'https://x.org/manifest.json',
    name: 'X',
    catalogs: [
      ArchiveCatalog(
          type: ArchiveType.movie, id: 'clips', name: 'Clips', wireType: 'xxx'),
      ArchiveCatalog(type: ArchiveType.series, id: 'shows', name: 'Shows'),
    ],
  );
  const normal = ArchiveSource(
    manifestUrl: 'https://n.org/manifest.json',
    name: 'N',
    catalogs: [
      ArchiveCatalog(type: ArchiveType.series, id: 'tv', name: 'TV'),
    ],
  );

  Future<ArchiveService> service() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyArchiveSources:
          jsonEncode([adult.toJson(), normal.toJson()]),
    });
    final storage = StorageService();
    await storage.init();
    return ArchiveService(storage);
  }

  // Owner, 2026-11-02: off for every source until the user turns it on.
  test('no source is under Other until the user turns it on', () {
    expect(adult.underOther, isFalse);
    expect(adult.copyWith(otherChoice: true).underOther, isTrue);
    expect(normal.underOther, isFalse);
    // Stream-only sources never are.
    expect(
        const ArchiveSource(
                manifestUrl: 'https://s.org/manifest.json',
                name: 'S',
                catalogProviderUrl: 'https://cinemeta',
                catalogs: [
                  ArchiveCatalog(
                      type: ArchiveType.movie,
                      id: 'c',
                      name: 'C',
                      wireType: 'tv'),
                ]).underOther,
        isFalse);
  });

  test('TV Shows offers Other for its shows; the switch moves it', () async {
    final s = await service();
    await s.setUnderOther(s.sources.first, true);
    expect(s.genres(ArchiveType.series), [ArchiveService.otherGenre]);

    await s.setUnderOther(s.sources.first, false);
    expect(s.sources.first.underOther, isFalse);
    expect(s.genres(ArchiveType.series), isEmpty);

    await s.setUnderOther(s.sources.first, true);
    expect(s.sources.first.underOther, isTrue);
    // Kept through a save/load round trip.
    expect(ArchiveSource.fromJson(s.sources.first.toJson()).otherChoice,
        isTrue);
  });
}
