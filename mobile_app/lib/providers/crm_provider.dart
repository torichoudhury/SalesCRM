import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

// Helper: unwrap paginated {count, next, previous, results} or plain List
List<dynamic> _unwrapList(dynamic body) {
  if (body is Map && body.containsKey('results')) {
    return body['results'] as List<dynamic>;
  }
  if (body is List) return body;
  return [];
}

// ─── Customers ───────────────────────────────────────────────────────────────

final customersProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/customers/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load customers');
});

final customerDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final response = await apiClient.get('/crm/customers/$id/');
  if (response.statusCode == 200) return jsonDecode(response.body);
  throw Exception('Failed to load customer');
});

// ─── Contacts ────────────────────────────────────────────────────────────────

final contactsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/contacts/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load contacts');
});

// Per-guide: contacts filtered by customer use ?customer= query param
final contactsByCustomerProvider = FutureProvider.family<List<dynamic>, int>((ref, customerId) async {
  final response = await apiClient.get('/crm/contacts/?customer=$customerId');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load contacts');
});

// ─── Opportunities ────────────────────────────────────────────────────────────

final opportunitiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/opportunities/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load opportunities');
});

final opportunitiesKanbanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await apiClient.get('/crm/opportunities/kanban/');
  if (response.statusCode == 200) return jsonDecode(response.body);
  throw Exception('Failed to load kanban data');
});

// ─── Quotes ──────────────────────────────────────────────────────────────────

final quotesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/quotes/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load quotes');
});

final quotesByOpportunityProvider = FutureProvider.family<List<dynamic>, int>((ref, oppId) async {
  final all = await ref.watch(quotesProvider.future);
  return all.where((q) {
    final opp = q['opportunity'];
    if (opp is Map) return opp['id'] == oppId;
    return opp == oppId;
  }).toList();
});

// ─── Sales Orders ────────────────────────────────────────────────────────────

final salesOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/sales-orders/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load sales orders');
});

// ─── Invoices ────────────────────────────────────────────────────────────────

final invoicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/invoices/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load invoices');
});

// Per-guide: endpoint is /crm/invoices/ar-ageing/ (hyphenated)
final arAgeingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await apiClient.get('/crm/invoices/ar-ageing/');
  if (response.statusCode == 200) return jsonDecode(response.body);
  throw Exception('Failed to load AR ageing');
});

// ─── Log Notes ───────────────────────────────────────────────────────────────

final logNotesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await apiClient.get('/crm/log-notes/');
  if (response.statusCode == 200) return _unwrapList(jsonDecode(response.body));
  throw Exception('Failed to load log notes');
});
