// lib/src/api_client.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  final String apiKey;
  final String? baseUrl;
  final String apiVersion;
  final http.Client _httpClient;

  ApiClient({
    required this.apiKey,
    this.baseUrl,
    this.apiVersion = 'v1beta',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Uri _buildUri(String path) {
    final effectiveBaseUrl =
        baseUrl ?? 'https://generativelanguage.googleapis.com';
    return Uri.parse('$effectiveBaseUrl/$apiVersion/$path?key=$apiKey');
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _buildUri(path);
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  void close() {
    _httpClient.close();
  }
}
