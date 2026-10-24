import 'package:flutter_test/flutter_test.dart';
import 'package:localshop_shared/localshop_shared.dart';
import 'package:mobile_client/core/i18n/date_text.dart';

void main() {
  final at = DateTime(2026, 10, 4, 9, 5);

  test('month names follow the app language, not intl defaults', () {
    expect(formatShortDateTime(at, SupportedLanguage.uz), '4 okt, 09:05');
    expect(formatShortDateTime(at, SupportedLanguage.ru), '4 окт, 09:05');
    expect(formatShortDateTime(at, SupportedLanguage.en), '4 Oct, 09:05');
  });

  test('time is zero-padded', () {
    expect(formatTime(DateTime(2026, 1, 1, 7, 3)), '07:03');
  });
}
