import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../ui/ui.dart';
import 'widgets/language_segmented_control.dart';
import 'widgets/onboarding_slides.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final slides = [
      OnboardingSlide(scene: IntroScene.shop, title: ref.t('welcome.slide1Title'), subtitle: ref.t('welcome.slide1Subtitle')),
      OnboardingSlide(scene: IntroScene.bag, title: ref.t('welcome.slide2Title'), subtitle: ref.t('welcome.slide2Subtitle')),
      OnboardingSlide(scene: IntroScene.delivery, title: ref.t('welcome.slide3Title'), subtitle: ref.t('welcome.slide3Subtitle')),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Picks up where the splash left off: logo drops in, then the
                  // slides rise, then the bottom panel slides up.
                  const AppLogo(size: 38)
                      .animate()
                      .fadeIn(duration: AppDurations.slow)
                      .moveY(begin: -12, end: 0, duration: 420.ms, curve: AppCurves.emphasized),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: OnboardingSlides(slides: slides),
                    ).animate(delay: 120.ms).fadeIn(duration: 420.ms).scaleXY(begin: 0.96, end: 1, curve: AppCurves.emphasized),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl + bottomInset),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
              boxShadow: AppShadows.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Text(ref.t('welcome.chooseLanguage'), style: AppText.label),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LanguageSegmentedControl(
                      value: locale,
                      onChanged: (lang) => ref.read(localeProvider.notifier).change(lang),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: ref.t('welcome.continue'),
                      icon: LucideIcons.arrowRight,
                      onPressed: () => context.go('/auth/phone'),
                    ),
                  ],
                ),
              ),
            ),
          ).animate(delay: 220.ms).fadeIn(duration: AppDurations.slow).moveY(begin: 24, end: 0, curve: AppCurves.emphasized),
        ],
      ),
    );
  }
}
