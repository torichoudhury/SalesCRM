import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String get baseUrl => 'https://salescrm-production-5257.up.railway.app/api/mobile/v1';

  String? _accessToken;
  String? _refreshToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  bool hasTokens() => _accessToken != null;

  Future<void> setTokens(String access, String? refresh) async {
    _accessToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    if (refresh != null) {
      _refreshToken = refresh;
      await prefs.setString('refresh_token', refresh);
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<bool> _refreshTokenRequest() async {
    if (_refreshToken == null) return false;
    final url = Uri.parse('$baseUrl/token/refresh/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'];
        if (newAccess != null) {
          await setTokens(newAccess, data['refresh'] ?? _refreshToken);
          return true;
        }
      }
    } catch (_) {}
    await clearTokens();
    return false;
  }

  Future<http.Response> _requestWithRetry(Future<http.Response> Function() requestFunc) async {
    http.Response response = await requestFunc();
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _refreshTokenRequest();
      if (refreshed) {
        response = await requestFunc();
      }
    }
    return response;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _requestWithRetry(() => http.get(url, headers: _getHeaders()));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _requestWithRetry(() => http.post(url, headers: _getHeaders(), body: jsonEncode(body)));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _requestWithRetry(() => http.put(url, headers: _getHeaders(), body: jsonEncode(body)));
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _requestWithRetry(() => http.patch(url, headers: _getHeaders(), body: jsonEncode(body)));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _requestWithRetry(() => http.delete(url, headers: _getHeaders()));
  }
}

final apiClient = ApiClient();

