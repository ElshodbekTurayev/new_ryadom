import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../ui/ui.dart';
import 'favorites_controller.dart';

/// Round heart toggle for a shop: white disc, red filled heart when saved,
/// with a little pop on change. Used on shop cards and the shop header.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.shopId, this.size = 40});

  final String shopId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoriteShopsProvider.select((ids) => ids.contains(shopId)));
    return Semantics(
      button: true,
      toggled: saved,
      label: ref.t(saved ? 'favorites.remove' : 'favorites.add'),
      child: Tooltip(
        message: ref.t(saved ? 'favorites.remove' : 'favorites.add'),
        child: Pressable(
          scale: 0.88,
          onTap: () {
            HapticFeedback.lightImpact();
            final added = ref.read(favoriteShopsProvider.notifier).toggle(shopId);
            showAppToast(
              context,
              ref.t(added ? 'favorites.added' : 'favorites.removed'),
              tone: added ? ToastTone.success : ToastTone.neutral,
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: AppShadows.sm),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              switchInCurve: AppCurves.spring,
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              // Lucide has no filled heart; Material's solid one marks "saved".
              child: Icon(
                saved ? Icons.favorite_rounded : LucideIcons.heart,
                key: ValueKey(saved),
                size: size * 0.48,
                color: saved ? _heartRed : AppColors.ink700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _heartRed = Color(0xFFE5484D);
