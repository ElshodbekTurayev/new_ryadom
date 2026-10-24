import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localshop_shared/localshop_shared.dart';
import 'package:mobile_client/core/errors/app_exception.dart';
import 'package:mobile_client/core/i18n/i18n_service.dart';
import 'package:mobile_client/features/shops/domain/product.dart';

DioException _response(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppException.fromDioException', () {
    test('reads the flat { code, message } envelope of HttpExceptionFilter', () {
      final e = AppException.fromDioException(
        _response(400, {'statusCode': 400, 'code': 'INVALID_SMS_CODE', 'message': 'Incorrect verification code entered.'}),
      );
      expect(e.code, 'INVALID_SMS_CODE');
      expect(e.statusCode, 400);
      expect(e.isUnauthorized, isFalse);
    });

    test('still accepts the legacy nested { error: { code } } shape', () {
      final e = AppException.fromDioException(_response(409, {'error': {'code': 'OUT_OF_STOCK', 'message': 'x'}}));
      expect(e.code, 'OUT_OF_STOCK');
    });

    test('reads Retry-After on rate limits', () {
      final options = RequestOptions(path: '/auth/send-code');
      final e = AppException.fromDioException(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 429,
          data: {'code': 'TOO_MANY_REQUESTS', 'message': 'ThrottlerException'},
          headers: Headers.fromMap({
            'retry-after': ['499'],
          }),
        ),
      ));
      expect(e.code, 'TOO_MANY_REQUESTS');
      expect(e.retryAfter, const Duration(seconds: 499));
    });

    test('marks 401 as unauthorized', () {
      final e = AppException.fromDioException(_response(401, {'code': 'UNAUTHORIZED', 'message': 'no'}));
      expect(e.isUnauthorized, isTrue);
    });

    test('maps connection failures and timeouts to network codes', () {
      final options = RequestOptions(path: '/x');
      final offline = AppException.fromDioException(DioException(requestOptions: options, type: DioExceptionType.connectionError));
      final slow = AppException.fromDioException(DioException(requestOptions: options, type: DioExceptionType.receiveTimeout));
      expect(offline.code, AppException.networkError);
      expect(slow.code, AppException.timeout);
      expect(offline.isNetwork && slow.isNetwork, isTrue);
    });
  });

  test('every error code has a translation in all three languages', () async {
    final i18n = I18nService();
    await i18n.load();
    const codes = ['NETWORK_ERROR', 'TIMEOUT', 'INVALID_SMS_CODE', 'OUT_OF_STOCK', 'SHOP_CLOSED', 'INVALID_PROMO_CODE'];
    for (final lang in SupportedLanguage.values) {
      for (final code in codes) {
        expect(i18n.t(lang, 'errors.$code'), isNot('errors.$code'), reason: '${lang.value}: $code');
      }
    }
  });

  group('Product localization', () {
    const product = Product(
      id: 'p1',
      shopId: 's1',
      categoryId: 'c1',
      nameUz: 'Non',
      nameRu: 'Хлеб',
      price: 400000,
      stock: 3,
      isAvailable: true,
    );

    test('shows the name in the UI language, falling back to uz', () {
      expect(product.localizedName(SupportedLanguage.ru), 'Хлеб');
      expect(product.localizedName(SupportedLanguage.en), 'Non');
    });

    test('search matches any translation', () {
      expect(product.matchesQuery('хлеб'), isTrue);
      expect(product.matchesQuery('non'), isTrue);
      expect(product.matchesQuery('milk'), isFalse);
    });
  });
}
