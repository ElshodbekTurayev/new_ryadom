import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localshop_shared/localshop_shared.dart';
import 'package:mobile_client/core/i18n/i18n_service.dart';
import 'package:mobile_client/core/providers.dart';
import 'package:mobile_client/features/auth/domain/app_user.dart';
import 'package:mobile_client/features/auth/presentation/auth_controller.dart';
import 'package:mobile_client/features/favorites/presentation/favorite_button.dart';
import 'package:mobile_client/features/favorites/presentation/favorites_controller.dart';
import 'package:mobile_client/features/favorites/presentation/favorites_screen.dart';
import 'package:mobile_client/features/shops/domain/shop.dart';
import 'package:mobile_client/features/shops/presentation/shop_detail_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends AuthController {
  _FakeAuth(this.id);
  final String id;

  @override
  Future<AppUser?> build() async => AppUser(id: id, phone: '+998901234567', name: 'Sardor', role: UserRole.customer, language: SupportedLanguage.uz);
}

const _shop = Shop(
  id: 's1',
  name: 'Chilonzor Market',
  phone: '',
  addressText: 'Test',
  lat: 41.3,
  lng: 69.2,
  openTime: '08:00',
  closeTime: '22:00',
  isOpen: true,
  isCurrentlyOpen: true,
  distanceMeters: 500,
  productCount: 3,
);

void main() {
  late I18nService i18n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    i18n = I18nService();
    await i18n.load();
  });

  test('toggle saves per user and survives a new container', () async {
    ProviderContainer make(String user) => ProviderContainer(overrides: [authControllerProvider.overrideWith(() => _FakeAuth(user))]);

    final a = make('u1');
    await a.read(authControllerProvider.future);
    a.read(favoriteShopsProvider);
    await Future<void>.delayed(Duration.zero);
    expect(a.read(favoriteShopsProvider.notifier).toggle('s1'), isTrue);
    expect(a.read(favoriteShopsProvider.notifier).toggle('s2'), isTrue);
    expect(a.read(favoriteShopsProvider), ['s2', 's1']); // newest first
    expect(a.read(favoriteShopsProvider.notifier).toggle('s2'), isFalse);
    await Future<void>.delayed(Duration.zero);
    a.dispose();

    final again = make('u1');
    await again.read(authControllerProvider.future);
    again.read(favoriteShopsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(again.read(favoriteShopsProvider), ['s1']);
    again.dispose();

    final other = make('u2');
    await other.read(authControllerProvider.future);
    other.read(favoriteShopsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(other.read(favoriteShopsProvider), isEmpty);
    other.dispose();
  });

  testWidgets('heart toggles and the favourites screen lists the saved shop', (tester) async {
    final container = ProviderContainer(overrides: [
      i18nServiceProvider.overrideWithValue(i18n),
      authControllerProvider.overrideWith(() => _FakeAuth('u1')),
      shopDetailProvider.overrideWith((ref, id) async => _shop),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: Center(child: FavoriteButton(shopId: 's1')))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FavoriteButton));
    await tester.pump();
    expect(find.text('Sevimlilarga qo\x27shildi'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(container.read(favoriteShopsProvider), ['s1']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: FavoritesScreen()),
    ));
    // The shop card has a looping status pulse, so pump frames instead of settling.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Sevimlilarim'), findsOneWidget);
    expect(find.text('Chilonzor Market'), findsOneWidget);
  });

  testWidgets('empty favourites explain how to add one', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        i18nServiceProvider.overrideWithValue(i18n),
        authControllerProvider.overrideWith(() => _FakeAuth('u1')),
      ],
      child: const MaterialApp(home: FavoritesScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hali sevimli do\'kon yo\'q'), findsOneWidget);
  });
}
