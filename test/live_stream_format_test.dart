import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/services/live_stream_format.dart';

void main() {
  tearDown(() => LiveStreamFormat.hlsAccounts = () => const []);

  test('HLS playlists open live .ts links as .m3u8', () {
    LiveStreamFormat.hlsAccounts = () => ['/live/u1/p1/'];
    expect(LiveStreamFormat.urlFor('http://a.tv/live/u1/p1/42.ts'),
        'http://a.tv/live/u1/p1/42.m3u8');
  });

  test('other accounts, movies and non-.ts links are unchanged', () {
    LiveStreamFormat.hlsAccounts = () => ['/live/u1/p1/'];
    for (final url in [
      'http://a.tv/live/u2/p2/42.ts',
      'http://a.tv/movie/u1/p1/7.mkv',
      'http://a.tv/live/u1/p1/42.m3u8',
    ]) {
      expect(LiveStreamFormat.urlFor(url), url);
    }
  });

  test('nothing changes when no playlist uses HLS', () {
    expect(LiveStreamFormat.urlFor('http://a.tv/live/u1/p1/42.ts'),
        'http://a.tv/live/u1/p1/42.ts');
  });
}
