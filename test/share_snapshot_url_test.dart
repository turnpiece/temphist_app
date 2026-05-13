import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/constants/app_constants.dart';

void main() {
  group('canonicalShareSnapshotUrl', () {
    test('rewrites dev API host to temphist.com', () {
      expect(
        canonicalShareSnapshotUrl(
            'https://devapi.temphist.com/s/mSRJfR50'),
        'https://temphist.com/s/mSRJfR50',
      );
    });

    test('leaves production URL unchanged', () {
      expect(
        canonicalShareSnapshotUrl(
            'https://temphist.com/s/mSRJfR50'),
        'https://temphist.com/s/mSRJfR50',
      );
    });

    test('handles relative path', () {
      expect(
        canonicalShareSnapshotUrl('/s/abc123'),
        'https://temphist.com/s/abc123',
      );
    });

    test('returns trimmed input when no /s/ segment', () {
      expect(
        canonicalShareSnapshotUrl('https://example.com/foo'),
        'https://example.com/foo',
      );
    });
  });
}
