import 'package:localshop_shared/localshop_shared.dart';

const _months = {
  SupportedLanguage.uz: ['yan', 'fev', 'mar', 'apr', 'may', 'iyn', 'iyl', 'avg', 'sen', 'okt', 'noy', 'dek'],
  SupportedLanguage.ru: ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'],
  SupportedLanguage.en: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
};

String _two(int n) => n.toString().padLeft(2, '0');

/// "14:05" in local time.
String formatTime(DateTime at) {
  final local = at.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// "24 okt, 14:05" / "24 окт, 14:05" / "24 Oct, 14:05" in local time.
/// Hand-rolled month names: intl's DateFormat has no uz data loaded and
/// silently fell back to English.
String formatShortDateTime(DateTime at, SupportedLanguage lang) {
  final local = at.toLocal();
  final month = (_months[lang] ?? _months[SupportedLanguage.uz]!)[local.month - 1];
  return '${local.day} $month, ${formatTime(local)}';
}
