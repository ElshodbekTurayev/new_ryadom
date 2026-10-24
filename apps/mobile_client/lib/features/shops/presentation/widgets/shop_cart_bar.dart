import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../ui/ui.dart';
import '../../../cart/presentation/cart_controller.dart';

/// Height of the floating bar; the grid reserves this much extra bottom room.
const double kShopCartBarHeight = 56;

/// Green bar that slides up from the bottom while this shop's cart has items.
/// Watches only (shopId, itemCount, totalAmount) so product tiles never rebuild.
class ShopCartBar extends ConsumerWidget {
  const ShopCartBar({super.key, required this.shopId, this.maxWidth = 560});

  final String shopId;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (cartShopId, count, total) = ref.watch(cartControllerProvider.select((c) => (c.shopId, c.itemCount, c.totalAmount)));
    final visible = cartShopId == shopId && count > 0;
    const duration = Duration(milliseconds: 240);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        duration: duration,
        curve: AppCurves.emphasized,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: AppCurves.standard,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Pressable(
                onTap: () => context.push('/cart'),
                haptic: true,
                scale: 0.98,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF168060), Color(0xFF0F5C45), Color(0xFF093E2F)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.rCard),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.25), width: 1.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4D0F5C45), blurRadius: 24, offset: Offset(0, 8)),
                      BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.28), width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.shoppingBag, size: 18, color: AppColors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          // The bag icon already says "cart"; the count alone fits on narrow phones.
                          ref.t('cart.itemsCount', {'count': '$count'}),
                          style: AppText.button.onBrand.copyWith(letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedPriceText(
                              total,
                              style: AppText.price.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
