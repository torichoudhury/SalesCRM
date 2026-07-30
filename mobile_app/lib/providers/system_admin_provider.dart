import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

List<dynamic> _unwrapList(dynamic body) {
  if (body is Map && body.containsKey('results')) return body['results'] as List<dynamic>;
  if (body is List) return body;
  return [];
}

// Per-guide: system admin endpoints use /admin/ prefix (not /system_admin/)

final usersProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/admin/users/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load users');
});

final rolesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/admin/roles/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load roles');
});

final subsidiariesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/admin/subsidiaries/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load subsidiaries');
});
