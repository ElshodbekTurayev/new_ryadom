import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localshop_shared/localshop_shared.dart';
import 'package:mobile_client/core/i18n/i18n_service.dart';
import 'package:mobile_client/core/providers.dart';
import 'package:mobile_client/features/auth/domain/app_user.dart';
import 'package:mobile_client/features/auth/presentation/auth_controller.dart';
import 'package:mobile_client/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed-in customer without network: saving a name / language only updates
/// local state.
class _FakeAuth extends AuthController {
  @override
  Future<AppUser?> build() async =>
      const AppUser(id: 'u1', phone: '+998901234567', name: 'Sardor', role: UserRole.customer, language: SupportedLanguage.uz);

  @override
  Future<void> saveName(String name) async {
    final u = state.valueOrNull!;
    state = AsyncData(AppUser(id: u.id, phone: u.phone, name: name, role: u.role, language: u.language));
  }

  @override
  Future<void> changeLanguage(String languageCode) async {}
}

void main() {
  late I18nService i18n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    i18n = I18nService();
    await i18n.load();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nServiceProvider.overrideWithValue(i18n),
          authControllerProvider.overrideWith(_FakeAuth.new),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('language lives behind one row that opens all three languages', (tester) async {
    await pump(tester);

    // Only the current language is on the page itself.
    expect(find.text('Ilova tili'), findsOneWidget);
    expect(find.text("O'zbekcha"), findsOneWidget);
    expect(find.text('Русский'), findsNothing);

    await tester.tap(find.text('Ilova tili'));
    await tester.pumpAndSettle();
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Sheet closed, UI switched to English.
    expect(find.text('Русский'), findsNothing);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('edit profile saves a new name and keeps the phone read-only', (tester) async {
    await pump(tester);
    expect(find.text('Sardor'), findsOneWidget);

    await tester.tap(find.text('Profilni tahrirlash'));
    await tester.pumpAndSettle();

    expect(find.text('+998 90 123 45 67'), findsWidgets);
    final phoneField = tester.widget<TextField>(find.widgetWithText(TextField, '+998 90 123 45 67'));
    expect(phoneField.enabled, isFalse);

    await tester.enterText(find.widgetWithText(TextField, 'Sardor'), 'Aziz');
    await tester.pump();
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('Aziz'), findsOneWidget);
    expect(find.text('Sardor'), findsNothing);
    expect(find.text('Profil saqlandi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3)); // let the toast time out
    await tester.pumpAndSettle();
  });
}
