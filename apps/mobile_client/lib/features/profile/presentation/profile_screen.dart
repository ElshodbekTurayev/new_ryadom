import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localshop_shared/localshop_shared.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../ui/ui.dart';
import '../../auth/presentation/auth_controller.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/language_sheet.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_row.dart';

const double _kMaxContentWidth = 560;
const String _kAppVersion = '1.0.0';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final lang = await showLanguageSheet(context, ref);
    if (lang == null || !context.mounted) return;
    await _changeLanguage(context, ref, lang);
  }

  Future<void> _changeLanguage(BuildContext context, WidgetRef ref, SupportedLanguage lang) async {
    if (ref.read(localeProvider) == lang) return;
    // Persist locally first so the UI flips immediately, then sync the
    // preference to the profile (no-op for guests).
    await ref.read(localeProvider.notifier).change(lang);
    if (!context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).changeLanguage(lang.value);
    } on AppException catch (e) {
      if (context.mounted) showAppToast(context, ref.errorText(e), tone: ToastTone.error);
    } on Exception {
      if (context.mounted) showAppToast(context, ref.t('common.error'), tone: ToastTone.error);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirm(
      context,
      title: ref.t('profile.logoutButton'),
      message: ref.t('profile.logoutQuestion'),
      confirmLabel: ref.t('common.logout'),
      cancelLabel: ref.t('common.cancel'),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  void _showSupport(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      builder: (_) => EmptyState(
        compact: true,
        illustration: AppIllustration.empty,
        title: ref.t('profile.support'),
        subtitle: ref.t('profile.supportSoon'),
      ),
    );
  }

  void _showAbout(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      title: ref.t('profile.about'),
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.md)),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.store, size: 26, color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ref.t('common.appName'), style: AppText.h3),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(ref.t('profile.version', {'version': _kAppVersion}), style: AppText.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(ref.t('welcome.subtitle'), style: AppText.body.secondary),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final locale = ref.watch(localeProvider);
    final name = (user?.name ?? '').trim().isEmpty ? ref.t('profile.defaultName') : user!.name!.trim();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xxxl, AppSpacing.page, AppSpacing.xxxl),
              physics: const BouncingScrollPhysics(),
              children: [
                ProfileHeader(name: name, phone: user?.phone),
                if (user != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: AppButton(
                      label: ref.t('profile.editProfile'),
                      icon: LucideIcons.userPen,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.md,
                      expand: false,
                      onPressed: () => showEditProfileSheet(context, ref),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),
                AppSection(
                  title: ref.t('profile.settingsSection'),
                  padding: EdgeInsets.zero,
                  child: ProfileRow(
                    icon: LucideIcons.languages,
                    title: ref.t('profile.appLanguage'),
                    subtitle: languageDisplayName(locale),
                    onTap: () => _pickLanguage(context, ref),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppSection(
                  title: ref.t('profile.helpSection'),
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ProfileRow(
                        icon: LucideIcons.lifeBuoy,
                        title: ref.t('profile.support'),
                        onTap: () => _showSupport(context, ref),
                      ),
                      const ProfileRowDivider(indentForIcon: true),
                      ProfileRow(
                        icon: LucideIcons.info,
                        title: ref.t('profile.about'),
                        subtitle: ref.t('profile.version', {'version': _kAppVersion}),
                        onTap: () => _showAbout(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(
                  label: ref.t('profile.logoutButton'),
                  icon: LucideIcons.logOut,
                  variant: AppButtonVariant.danger,
                  onPressed: () => _logout(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
