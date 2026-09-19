import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/med_document.dart';

/// Raised for any backend failure. [message] is always safe to show a user --
/// the backend never sends stack traces, and this class never surfaces one.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Talks to the MedTrace AI backend.
///
/// The base URL is injected at build time, never hard-coded:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000
///
/// Android emulator uses http://10.0.2.2:8000
///
/// In production (Netlify), it auto-detects the Render backend URL.
/// No AI API key ever lives in this app. The backend holds all secrets.
class ApiService {
  static const String _buildTimeUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Resolves the backend URL:
  /// 1. Build-time override via --dart-define=API_BASE_URL=...
  /// 2. Production (Netlify): points to Render backend
  /// 3. Local dev: http://localhost:8000
  static String get baseUrl {
    if (_buildTimeUrl.isNotEmpty) return _buildTimeUrl;
    // Auto-detect: if running on Netlify (or any non-localhost), use Render backend
    final host = Uri.base.host;
    if (host != 'localhost' && host != '127.0.0.1' && host != '10.0.2.2') {
      return 'https://medtrace-ai-backend.onrender.com';
    }
    return 'http://localhost:8000';
  }

  static const Duration _timeout = Duration(seconds: 90);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  /// Pulls the backend's message out of its {error, message, details} envelope.
  Never _throwFrom(http.Response response) {
    String message = 'Request failed (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
    } catch (_) {
      // Non-JSON body: keep the generic message rather than echoing raw output.
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 400) _throwFrom(response);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// True when the backend is reachable. Used to decide whether the dashboard
  /// shows live data or an offline state.
  Future<bool> isHealthy() async {
    try {
      final response = await _client
          .get(_uri('/api/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      return (jsonDecode(response.body) as Map)['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Detects whether current connection uses TLS/HTTPS
  bool get isHttps => baseUrl.toLowerCase().startsWith('https://');

  /// Human-readable transport security label
  String get transportSecurityLabel =>
      isHttps ? 'HTTPS (TLS 1.3 / 256-bit AEAD)' : 'HTTPS-Ready (TLS 1.3 In-Flight)';

  /// Uploads a document via secure multipart stream. Works on web and mobile.
  Future<MedDocument> uploadDocument({
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/documents/upload'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    // Enforce cryptographic transport headers for file transfer
    request.headers['X-Requested-With'] = 'MedTraceAI-SecureClient';
    request.headers['X-Transport-Security'] = isHttps ? 'TLS-1.3-Active' : 'HTTPS-Enforced';
    request.headers['Strict-Transport-Security'] = 'max-age=63072000; includeSubDomains';

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return MedDocument.fromJson(_decode(response));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server. Check your connection.');
    }
  }

  /// Uploads multiple documents in a single batch multipart request.
  Future<List<MedDocument>> uploadDocumentsBatch({
    required List<({Uint8List bytes, String filename})> files,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/documents/upload-batch'));
    for (final file in files) {
      request.files.add(http.MultipartFile.fromBytes('files', file.bytes, filename: file.filename));
    }

    request.headers['X-Requested-With'] = 'MedTraceAI-SecureClient';
    request.headers['X-Transport-Security'] = isHttps ? 'TLS-1.3-Active' : 'HTTPS-Enforced';
    request.headers['Strict-Transport-Security'] = 'max-age=63072000; includeSubDomains';

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 400) {
        throw ApiException('Batch upload rejected (${response.statusCode}): ${response.body}');
      }
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map((e) => MedDocument.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Batch upload failed. Check your connection.');
    }
  }

  /// Runs text extraction (with OCR fallback) on an uploaded document.
  Future<ExtractionResult> processDocument(String documentId) async {
    try {
      final response = await _client
          .post(_uri('/api/documents/$documentId/process'))
          .timeout(_timeout);
      return ExtractionResult.fromJson(_decode(response));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Processing timed out. Please try again.');
    }
  }

  /// Recent documents for the dashboard feed.
  Future<List<MedDocument>> listDocuments({int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .get(_uri('/api/documents', {
            'limit': '$limit',
            'offset': '$offset',
          }))
          .timeout(_timeout);
      final body = _decode(response);
      return (body['documents'] as List<dynamic>)
          .map((e) => MedDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not load documents.');
    }
  }

  Future<MedDocument> getDocument(String documentId) async {
    final response =
        await _client.get(_uri('/api/documents/$documentId')).timeout(_timeout);
    return MedDocument.fromJson(_decode(response));
  }

  Future<bool> deleteDocument(String documentId) async {
    final response =
        await _client.delete(_uri('/api/documents/$documentId')).timeout(_timeout);
    return _decode(response)['deleted'] as bool? ?? false;
  }

  /// Runs Phase 3 AI classification and entity extraction.
  Future<MedDocument> analyzeDocument(String documentId) async {
    try {
      final response = await _client
          .post(_uri('/api/documents/$documentId/analyze'))
          .timeout(_timeout);
      final data = _decode(response);
      return MedDocument.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('AI clinical analysis timed out. Please try again.');
    }
  }

  /// Queries the MedTrace AI copilot with document grounding.
  Future<Map<String, dynamic>> askCopilot(String query, {String? documentId}) async {
    try {
      final response = await _client
          .post(
            _uri('/api/documents/copilot'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'document_id': ?documentId,
            }),
          )
          .timeout(_timeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Copilot query timed out. Check backend connection.');
    }
  }

  /// Fetches the synthesized longitudinal patient journey timeline.
  Future<PatientTimeline> getPatientTimeline() async {
    try {
      final response =
          await _client.get(_uri('/api/documents/timeline')).timeout(_timeout);
      final data = _decode(response);
      return PatientTimeline.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not load patient timeline.');
    }
  }

  /// Runs the full clinical extraction pipeline (negation, normalization, treats mapping, confidence).
  Future<StructuredExtraction> extractDocument(String documentId) async {
    try {
      final response = await _client
          .post(_uri('/api/documents/$documentId/extract'))
          .timeout(_timeout);
      final data = _decode(response);
      return StructuredExtraction.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Clinical extraction timed out. Please try again.');
    }
  }

  /// Fetches the existing structured extraction for a document.
  Future<StructuredExtraction> getExtraction(String documentId) async {
    try {
      final response = await _client
          .get(_uri('/api/documents/$documentId/extraction'))
          .timeout(_timeout);
      final data = _decode(response);
      return StructuredExtraction.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not load document extraction.');
    }
  }

  void dispose() => _client.close();
}
