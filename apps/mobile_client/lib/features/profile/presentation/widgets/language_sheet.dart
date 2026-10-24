import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localshop_shared/localshop_shared.dart';

import '../../../../core/providers.dart';
import '../../../../ui/ui.dart';
import 'profile_row.dart';

/// Each language is named in itself so it is recognisable whatever the
/// current UI language is.
const kAppLanguages = [
  (SupportedLanguage.uz, "O'zbekcha"),
  (SupportedLanguage.ru, 'Русский'),
  (SupportedLanguage.en, 'English'),
];

String languageDisplayName(SupportedLanguage lang) =>
    kAppLanguages.firstWhere((l) => l.$1 == lang, orElse: () => kAppLanguages.first).$2;

/// Bottom sheet listing the three app languages. Resolves to the picked
/// language (null when dismissed); the caller applies it, since it outlives
/// the sheet.
Future<SupportedLanguage?> showLanguageSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet<SupportedLanguage>(
    context,
    title: ref.t('profile.appLanguage'),
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kAppLanguages.length; i++) ...[
          if (i > 0) const ProfileRowDivider(),
          ProfileRow(
            title: kAppLanguages[i].$2,
            subtitle: kAppLanguages[i].$1.value.toUpperCase(),
            selected: current == kAppLanguages[i].$1,
            trailing: current == kAppLanguages[i].$1
                ? const Icon(LucideIcons.check, size: 20, color: AppColors.brand)
                : const SizedBox(width: 20),
            onTap: () => Navigator.of(context).pop(kAppLanguages[i].$1),
          ),
        ],
      ],
    );
  }
}
