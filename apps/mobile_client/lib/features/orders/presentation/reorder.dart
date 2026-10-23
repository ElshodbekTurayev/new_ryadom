import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../ui/ui.dart';
import '../../cart/domain/cart_state.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../shops/domain/product.dart';
import '../../shops/presentation/home_controller.dart';
import '../domain/order.dart';

/// Puts every line of [order] back into the cart and opens it. Asks before
/// replacing a cart that belongs to a different shop. Shared by the orders
/// history list and the Home "last order" card so the behaviour never drifts.
///
/// Returns true when the cart was filled.
Future<bool> reorderOrder(BuildContext context, WidgetRef ref, Order order) async {
  final shopId = order.shopId;
  final items = order.items.where((i) => i.productId != null).toList();
  if (shopId == null || items.isEmpty) {
    showAppToast(context, ref.t('orders.reorderUnavailable'), tone: ToastTone.error);
    return false;
  }

  final cart = ref.read(cartControllerProvider);
  if (cart.shopId != null && cart.shopId != shopId && !cart.isEmpty) {
    final confirmed = await showAppConfirm(
      context,
      title: ref.t('cart.differentShopTitle'),
      message: ref.t('cart.multipleShopsWarning'),
      confirmLabel: ref.t('cart.clearCart'),
      cancelLabel: ref.t('common.cancel'),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return false;
  }

  // Prefer the shop's live catalogue: current prices (the backend charges
  // today's price, not the old order's), photos, translations and stock.
  // Lines that are gone or sold out are dropped. Offline: fall back to the
  // order snapshot and let checkout re-validate.
  Map<String, Product>? live;
  try {
    final products = await ref.read(shopsApiProvider).products(shopId);
    live = {for (final p in products) p.id: p};
  } catch (_) {
    live = null;
  }
  if (!context.mounted) return false;

  final lines = <CartItem>[];
  for (final i in items) {
    final current = live?[i.productId];
    if (live != null) {
      if (current == null || !current.isAvailable || current.stock <= 0) continue;
      lines.add(CartItem(product: current, quantity: i.quantity.clamp(1, current.stock)));
    } else {
      lines.add(CartItem(
        product: Product(
          id: i.productId!,
          shopId: shopId,
          categoryId: '',
          nameUz: i.productName,
          price: i.unitPrice,
          stock: 999,
          isAvailable: true,
        ),
        quantity: i.quantity,
      ));
    }
  }
  if (lines.isEmpty) {
    showAppToast(context, ref.t('orders.reorderUnavailable'), tone: ToastTone.error);
    return false;
  }

  ref.read(cartControllerProvider.notifier).reorder(shopId: shopId, shopName: order.shopName ?? '', items: lines);

  if (!context.mounted) return true;
  showAppToast(context, ref.t('orders.reorderSuccess'), tone: ToastTone.success);
  context.push('/cart');
  return true;
}
