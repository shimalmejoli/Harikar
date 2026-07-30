// test/update_service_test.dart
//
// Offline coverage for the update check: version comparison and the
// Play Store version extraction. Both are the parts that silently
// disable the update prompt when they regress.

import 'package:flutter_test/flutter_test.dart';
import 'package:harikar/services/update_service.dart';

void main() {
  group('isNewerVersion', () {
    test('detects a newer store release', () {
      expect(UpdateService.isNewerVersion('1.0.6', '1.0.5'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('compares segments numerically, not as text', () {
      // "1.0.10" sorts before "1.0.9" as a string — it must not here.
      expect(UpdateService.isNewerVersion('1.0.10', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.9', '1.0.10'), isFalse);
    });

    test('no prompt when up to date or ahead of the store', () {
      expect(UpdateService.isNewerVersion('1.0.5', '1.0.5'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.4', '1.0.5'), isFalse);
    });

    test('handles differing segment counts and build suffixes', () {
      expect(UpdateService.isNewerVersion('1.1', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.6+20', '1.0.5+18'), isTrue);
    });
  });

  group('extractPlayStoreVersion', () {
    final service = UpdateService.instance;

    test('reads the version out of the listing data blob', () {
      // Shape taken from the live listing of com.legaryan_kare.app.
      const html =
          'about how developers declare collection"]]],1],"141":[[["1.0.5"]],'
          '[[[35]],[[[21,"5.0"]]]';
      expect(service.extractPlayStoreVersion(html), '1.0.5');
    });

    test('falls back to the bracket pattern if the field is renumbered', () {
      const html = 'noise,"999":[[["2.3.4"]],more';
      expect(service.extractPlayStoreVersion(html), '2.3.4');
    });

    test('returns null when the page has no version cell', () {
      expect(service.extractPlayStoreVersion('<html>not a listing</html>'),
          isNull);
    });
  });
}
