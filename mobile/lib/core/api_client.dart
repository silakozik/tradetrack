import 'dart:convert';
import 'package:http/http.dart' as http;

import 'secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: await _authHeaders());
    return _handleResponse(response);
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body, {bool useAuth = true}) async {
    final headers = useAuth
        ? await _authHeaders()
        : {"Content-Type": "application/json"};

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(url),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<void> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: await _authHeaders());
    if (response.statusCode != 204 && response.statusCode != 200) {
      _handleResponse(response);
    }
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = "Bir hata oluştu.";
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded["detail"] != null) {
        final detail = decoded["detail"];
        message = detail is String ? detail : "Girdiğiniz bilgileri kontrol edin.";
      }
    } catch (_) {
      // JSON çözülemezse varsayılan mesaj kullanılır
    }

    if (statusCode == 401) {
      message = "Oturum süresi doldu, lütfen tekrar giriş yapın.";
    }

    throw ApiException(message, statusCode: statusCode);
  }
}