import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localshop_shared/localshop_shared.dart';

import '../../../../core/providers.dart';
import '../../../../ui/ui.dart';

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
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _LanguageOption(
            code: kAppLanguages[i].$1.value.toUpperCase(),
            name: kAppLanguages[i].$2,
            selected: current == kAppLanguages[i].$1,
            onTap: () => Navigator.of(context).pop(kAppLanguages[i].$1),
          ).animate(delay: (i * 40).ms).fadeIn(duration: AppDurations.normal).moveY(begin: 8, end: 0),
        ],
      ],
    );
  }
}

/// Selectable language card: code badge, native name, radio-style mark.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.code, required this.name, required this.selected, required this.onTap});

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        scale: 0.98,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.standard,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandSoft : AppColors.surface,
            borderRadius: AppRadius.control,
            border: Border.all(color: selected ? AppColors.brand : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppDurations.normal,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand : AppColors.ink50,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  code,
                  style: AppText.captionStrong.copyWith(color: selected ? AppColors.white : AppColors.ink700),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(name, style: selected ? AppText.bodyStrong : AppText.body)),
              AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: AppCurves.spring,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: selected
                    ? Container(
                        key: const ValueKey('on'),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check, size: 14, color: AppColors.white),
                      )
                    : Container(
                        key: const ValueKey('off'),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink300, width: 1.5),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
