import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../devlens.dart';

/// HTTP Client that automatically tracks all requests for DevLens
/// 
/// Use this instead of http.Client():
/// ```dart
/// final client = DevLensHttpClient();
/// final response = await client.get(Uri.parse('https://api.example.com/data'));
/// ```
class DevLensHttpClient extends http.BaseClient {
  final http.Client _inner;

  DevLensHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = _generateId();
    final startTime = DateTime.now();

    // Capture request body if available
    dynamic requestBody;
    if (request is http.Request && request.body.isNotEmpty) {
      requestBody = _tryParseJson(request.body);
    }

    try {
      final response = await _inner.send(request);
      final endTime = DateTime.now();

      // Read response body
      final bytes = await response.stream.toBytes();
      final responseBody = _decodeBody(bytes, response.headers['content-type']);

      // Record the request
      DevLens.instance.recordRequest(NetworkDataRecord(
        id: id,
        method: request.method,
        url: request.url,
        statusCode: response.statusCode,
        requestHeaders: Map<String, dynamic>.from(request.headers),
        responseHeaders: Map<String, dynamic>.from(response.headers),
        requestBody: requestBody,
        responseBody: responseBody,
        timestamp: startTime,
        duration: endTime.difference(startTime),
      ));

      // Return a new StreamedResponse with the same body
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      final endTime = DateTime.now();

      // Record failed request
      DevLens.instance.recordRequest(NetworkDataRecord(
        id: id,
        method: request.method,
        url: request.url,
        requestHeaders: Map<String, dynamic>.from(request.headers),
        requestBody: requestBody,
        timestamp: startTime,
        duration: endTime.difference(startTime),
        error: error.toString(),
      ));

      rethrow;
    }
  }

  dynamic _decodeBody(Uint8List bytes, String? contentType) {
    if (bytes.isEmpty) return null;

    final isJson = contentType?.contains('application/json') ?? false;
    final isText = contentType?.contains('text/') ??
        contentType?.contains('application/xml') ??
        isJson;

    if (isText) {
      final text = utf8.decode(bytes, allowMalformed: true);
      if (isJson) {
        return _tryParseJson(text);
      }
      return text;
    }

    // For binary data, just return info about size
    return {'_binary': true, '_size': bytes.length};
  }

  dynamic _tryParseJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  String _generateId() => 'http_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void close() {
    _inner.close();
  }
}

/// Extension to add DevLens tracking to any existing http.Client
extension DevLensHttpExtension on http.Client {
  /// Wrap this client with DevLens tracking
  DevLensHttpClient withDevLens() {
    return DevLensHttpClient(this);
  }
}