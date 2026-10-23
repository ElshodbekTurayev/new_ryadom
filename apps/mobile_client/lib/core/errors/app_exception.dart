import 'package:dio/dio.dart';

/// Normalized error surfaced to the UI, carrying the backend's error envelope
/// when available instead of a raw DioException.
///
/// The API's HttpExceptionFilter answers with a flat
/// `{ statusCode, code, message, timestamp, details? }` body; an older nested
/// `{ error: { code, message } }` shape is still accepted.
class AppException implements Exception {
  AppException(this.message, {this.code, this.statusCode});

  /// Developer-facing message (the backend's, usually English). Screens show
  /// a localized text picked by [code] instead — see `WidgetRef.errorText`.
  final String message;
  final String? code;
  final int? statusCode;

  static const networkError = 'NETWORK_ERROR';
  static const timeout = 'TIMEOUT';

  /// No response at all (offline, DNS, CORS, server down) or it timed out.
  bool get isNetwork => code == networkError || code == timeout;

  /// The session is gone (refresh failed / account blocked) rather than a
  /// transient failure.
  bool get isUnauthorized => statusCode == 401;

  factory AppException.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final nested = data['error'];
      final source = nested is Map ? nested : data;
      final code = source['code']?.toString();
      final message = source['message'];
      final text = message is List ? message.join(', ') : message?.toString();
      if (code != null || (text != null && text.isNotEmpty)) {
        return AppException(
          (text == null || text.isEmpty) ? 'Request failed' : text,
          code: code,
          statusCode: status,
        );
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
        return AppException('No connection to the server', code: networkError, statusCode: status);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('The server did not respond in time', code: timeout, statusCode: status);
      default:
        return AppException(e.message ?? 'Unexpected error', statusCode: status);
    }
  }

  @override
  String toString() => code == null ? message : '$code: $message';
}
