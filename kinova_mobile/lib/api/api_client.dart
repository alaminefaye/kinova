import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kinova_mobile/api/api_config.dart';
import 'package:kinova_mobile/api/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  String? get token => _token;

  void setToken(String? token) => _token = token;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: _headers());
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path, {Object? body}) async {
    final response = await _client.delete(
      _uri(path),
      headers: _headers(jsonBody: body != null),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    required String field,
    required File file,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers());
    request.files.add(await http.MultipartFile.fromPath(field, file.path));
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final raw = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return raw;
    }

    String message = 'Erreur serveur (${response.statusCode})';
    if (raw is Map) {
      if (raw['message'] is String && (raw['errors'] == null)) {
        message = raw['message'] as String;
      }
      if (raw['errors'] is Map) {
        final errors = raw['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          } else {
            message = first.toString();
          }
        }
      } else if (raw['message'] is String) {
        message = raw['message'] as String;
      }
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
