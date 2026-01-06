import 'package:dio/dio.dart';
import '../devlens.dart';

/// Dio interceptor that automatically tracks all requests
/// 
/// Just add this to your Dio instance:
/// ```dart
/// dio.interceptors.add(DevLensDioInterceptor());
/// ```
class DevLensDioInterceptor extends Interceptor {
  final Map<String, DateTime> _requestStartTimes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _generateId();
    options.extra['_devlens_id'] = id;
    _requestStartTimes[id] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _recordResponse(response.requestOptions, response.statusCode, response.data, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordResponse(
      err.requestOptions,
      err.response?.statusCode,
      err.response?.data,
      err.message,
    );
    handler.next(err);
  }

  void _recordResponse(
      RequestOptions options,
      int? statusCode,
      dynamic responseData,
      String? error,
      ) {
    final id = options.extra['_devlens_id'] as String? ?? _generateId();
    final startTime = _requestStartTimes.remove(id);
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;

    DevLens.instance.recordRequest(NetworkDataRecord(
      id: id,
      method: options.method,
      url: options.uri,
      statusCode: statusCode,
      requestHeaders: Map<String, dynamic>.from(options.headers),
      responseHeaders: {},
      requestBody: options.data,
      responseBody: responseData,
      timestamp: startTime ?? DateTime.now(),
      duration: duration,
      error: error,
    ));
  }

  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}';
}