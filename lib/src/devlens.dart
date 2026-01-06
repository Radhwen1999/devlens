import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'config/devlens_config.dart';

/// Core DevLens singleton that tracks all network data
class DevLens {
  static DevLens? _instance;
  static DevLens get instance {
    _instance ??= DevLens._();
    return _instance!;
  }

  DevLens._();

  DevLensConfig _config = const DevLensConfig();
  DevLensConfig get config => _config;

  /// All stored network records
  final List<NetworkDataRecord> _records = [];
  List<NetworkDataRecord> get records => List.unmodifiable(_records);

  /// Stream for updates
  final _recordsController = StreamController<List<NetworkDataRecord>>.broadcast();
  Stream<List<NetworkDataRecord>> get recordsStream => _recordsController.stream;

  /// Index of all string values to their JSON paths (for smart detection)
  /// Maps: displayValue -> List of (requestId, jsonPath)
  final Map<String, List<DataPathReference>> _valueIndex = {};

  /// Initialize DevLens
  static void init({DevLensConfig? config}) {
    if (config != null) {
      instance._config = config;
    }
    if (kDebugMode) {
      debugPrint('🔎 DevLens initialized');
    }
  }

  /// Record a new network request/response
  void recordRequest(NetworkDataRecord record) {
    _records.add(record);

    // Index all string values in the response for smart detection
    if (record.responseBody != null) {
      _indexResponseData(record.id, record.responseBody!, '');
    }

    // Trim old records
    while (_records.length > _config.maxRequests) {
      final removed = _records.removeAt(0);
      _removeFromIndex(removed.id);
    }

    _recordsController.add(_records);
  }

  /// Index all values in the response for quick lookup
  void _indexResponseData(String requestId, dynamic data, String path) {
    if (data == null) return;

    if (data is String) {
      _addToIndex(data, requestId, path);
      // Also index trimmed versions and common transformations
      _addToIndex(data.trim(), requestId, path);
      if (data.length > 50) {
        _addToIndex(data.substring(0, 50), requestId, path);
      }
    } else if (data is num) {
      _addToIndex(data.toString(), requestId, path);
      if (data is double) {
        // Index common decimal formats
        _addToIndex(data.toStringAsFixed(2), requestId, path);
        _addToIndex(data.toStringAsFixed(3), requestId, path);
      }
    } else if (data is bool) {
      _addToIndex(data.toString(), requestId, path);
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        _indexResponseData(requestId, data[i], '$path[$i]');
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        final newPath = path.isEmpty ? key.toString() : '$path.$key';
        _indexResponseData(requestId, value, newPath);
      });
    }
  }

  void _addToIndex(String value, String requestId, String path) {
    if (value.isEmpty) return;
    final key = value.toLowerCase();
    _valueIndex.putIfAbsent(key, () => []).add(
      DataPathReference(requestId: requestId, path: path, originalValue: value),
    );
  }

  void _removeFromIndex(String requestId) {
    _valueIndex.forEach((key, refs) {
      refs.removeWhere((ref) => ref.requestId == requestId);
    });
    _valueIndex.removeWhere((key, refs) => refs.isEmpty);
  }

  /// Smart detection: find which network data corresponds to a displayed value
  SmartDetectionResult? detectDataForValue(String displayedValue) {
    if (displayedValue.isEmpty) return null;

    final searchKey = displayedValue.toLowerCase().trim();

    // Direct match
    if (_valueIndex.containsKey(searchKey)) {
      final refs = _valueIndex[searchKey]!;
      if (refs.isNotEmpty) {
        final ref = refs.last; // Most recent
        final record = _records.firstWhere(
              (r) => r.id == ref.requestId,
          orElse: () => _records.last,
        );
        return SmartDetectionResult(
          record: record,
          matchedPath: ref.path,
          matchedValue: ref.originalValue,
          matchType: MatchType.exact,
        );
      }
    }

    // Partial match - search for values containing the displayed text
    for (final entry in _valueIndex.entries) {
      if (entry.key.contains(searchKey) || searchKey.contains(entry.key)) {
        final refs = entry.value;
        if (refs.isNotEmpty) {
          final ref = refs.last;
          final record = _records.firstWhere(
                (r) => r.id == ref.requestId,
            orElse: () => _records.last,
          );
          return SmartDetectionResult(
            record: record,
            matchedPath: ref.path,
            matchedValue: ref.originalValue,
            matchType: MatchType.partial,
          );
        }
      }
    }

    // No specific match - return most recent record if available
    if (_records.isNotEmpty) {
      return SmartDetectionResult(
        record: _records.last,
        matchedPath: null,
        matchedValue: null,
        matchType: MatchType.none,
      );
    }

    return null;
  }

  /// Get the most recent record
  NetworkDataRecord? get latestRecord => _records.isNotEmpty ? _records.last : null;

  /// Clear all records
  void clear() {
    _records.clear();
    _valueIndex.clear();
    _recordsController.add(_records);
  }

  void dispose() {
    _recordsController.close();
  }
}

/// A network request/response record
class NetworkDataRecord {
  final String id;
  final String method;
  final Uri url;
  final int? statusCode;
  final Map<String, dynamic> requestHeaders;
  final Map<String, dynamic> responseHeaders;
  final dynamic requestBody;
  final dynamic responseBody;
  final DateTime timestamp;
  final Duration? duration;
  final String? error;

  NetworkDataRecord({
    required this.id,
    required this.method,
    required this.url,
    this.statusCode,
    this.requestHeaders = const {},
    this.responseHeaders = const {},
    this.requestBody,
    this.responseBody,
    required this.timestamp,
    this.duration,
    this.error,
  });

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);

  String get formattedDuration {
    if (duration == null) return '--';
    if (duration!.inMilliseconds < 1000) return '${duration!.inMilliseconds}ms';
    return '${(duration!.inMilliseconds / 1000).toStringAsFixed(2)}s';
  }

  String get formattedResponseBody {
    if (responseBody == null) return 'null';
    try {
      return const JsonEncoder.withIndent('  ').convert(responseBody);
    } catch (_) {
      return responseBody.toString();
    }
  }
}

/// Reference to a value's location in a response
class DataPathReference {
  final String requestId;
  final String path;
  final String originalValue;

  DataPathReference({
    required this.requestId,
    required this.path,
    required this.originalValue,
  });
}

/// Result of smart detection
class SmartDetectionResult {
  final NetworkDataRecord record;
  final String? matchedPath;
  final String? matchedValue;
  final MatchType matchType;

  SmartDetectionResult({
    required this.record,
    this.matchedPath,
    this.matchedValue,
    required this.matchType,
  });
}

enum MatchType { exact, partial, none }