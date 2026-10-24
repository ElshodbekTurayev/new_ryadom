import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

/// "+998901234567" → "+998 90 123 45 67"; anything else is returned as-is.
String formatPhoneForDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 12) return raw;
  return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} '
      '${digits.substring(8, 10)} ${digits.substring(10, 12)}';
}

/// Brand-gradient hero card: avatar, name, formatted phone and an edit
/// button; [stats] (if any) sit in a frosted strip along the bottom.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.name, this.phone, this.onEdit, this.editTooltip, this.stats});

  final String name;
  final String? phone;
  final VoidCallback? onEdit;
  final String? editTooltip;
  final Widget? stats;

  @override
  Widget build(BuildContext context) {
    final phoneText = (phone == null || phone!.isEmpty) ? null : formatPhoneForDisplay(phone!);
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brand,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft decorative rings, purely visual.
          const Positioned(top: -60, right: -40, child: _Ring(size: 180)),
          const Positioned(bottom: -70, left: -50, child: _Ring(size: 160)),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.md, AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.22),
                      ),
                      child: AppAvatar(
                        name: name,
                        size: 64,
                        background: AppColors.white,
                        foreground: AppColors.brand,
                      ),
                    ).animate().fadeIn(duration: AppDurations.slow).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: AppDurations.slow,
                          curve: AppCurves.emphasized,
                        ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppText.h2.copyWith(color: AppColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (phoneText != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              phoneText,
                              style: AppText.bodyMedium.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ],
                      ).animate(delay: 40.ms).fadeIn(duration: AppDurations.slow).moveX(begin: 6, end: 0),
                    ),
                    if (onEdit != null)
                      Tooltip(
                        message: editTooltip ?? '',
                        child: Pressable(
                          onTap: onEdit,
                          haptic: true,
                          scale: 0.92,
                          child: Container(
                            width: kMinTapTarget,
                            height: kMinTapTarget,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.24)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.pencil, size: 18, color: AppColors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (stats != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.green900.withValues(alpha: 0.18),
                    border: Border(top: BorderSide(color: AppColors.white.withValues(alpha: 0.12))),
                  ),
                  child: stats,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One figure in the header's stats strip; a dash while [value] is unknown.
class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scale long sums ("1 250 000 so'm") down instead of truncating them.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              value ?? '—',
              key: ValueKey(value),
              style: AppText.h3.copyWith(color: AppColors.white, fontFeatures: const [FontFeature.tabularFigures()]),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppText.label.copyWith(color: AppColors.white.withValues(alpha: 0.75)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.08), width: 28),
        ),
      ),
    );
  }
}
