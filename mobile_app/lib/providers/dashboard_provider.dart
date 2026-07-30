import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

List<dynamic> _unwrapList(dynamic body) {
  if (body is Map && body.containsKey('results')) return body['results'] as List<dynamic>;
  if (body is List) return body;
  return [];
}

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Try to load from API; fall back to aggregated CRM data if dashboard API not available
  try {
    final response = await apiClient.get('/dashboard/summary/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (_) {}

  // Fallback: build a CRM-focused dashboard from crm endpoints
  Map<String, dynamic> customers = {'count': 0};
  Map<String, dynamic> opportunities = {'count': 0};
  Map<String, dynamic> invoices = {'count': 0, 'total': 0};

  try {
    final cResp = await apiClient.get('/crm/customers/');
    if (cResp.statusCode == 200) {
      final list = _unwrapList(jsonDecode(cResp.body));
      customers = {'count': list.length};
    }
  } catch (_) {}

  try {
    final oResp = await apiClient.get('/crm/opportunities/');
    if (oResp.statusCode == 200) {
      final list = _unwrapList(jsonDecode(oResp.body));
      final won = list.where((o) => o['stage'] == 'Won').length;
      final totalRevenue = list.where((o) => o['stage'] == 'Won').fold<double>(
          0, (sum, o) => sum + (double.tryParse(o['expected_revenue'].toString()) ?? 0));
      opportunities = {'count': list.length, 'won': won, 'total_revenue': totalRevenue};
    }
  } catch (_) {}

  try {
    final iResp = await apiClient.get('/crm/invoices/');
    if (iResp.statusCode == 200) {
      final list = _unwrapList(jsonDecode(iResp.body));
      final paid = list.where((i) => i['status'] == 'Paid').fold<double>(
          0, (sum, i) => sum + (double.tryParse(i['total'].toString()) ?? 0));
      invoices = {'count': list.length, 'paid_total': paid};
    }
  } catch (_) {}

  return {
    'kpis': {
      'total_revenue': opportunities['total_revenue'] ?? 0,
      'outstanding_receivables': 0,
      'gross_profit': opportunities['total_revenue'] ?? 0,
    },
    'crm_performance': {
      'customers': customers['count'],
      'opportunities': opportunities['count'],
    },
    'sales_metrics': {
      'sales_orders': 0,
      'pending_invoices': 0
    },
    'quote_metrics': {
      'active_quotes': 0,
      'unpaid_amount': 0.0
    },
    'inventory_status': {'low_stock': 0, 'critical_stock': 0},
    'reservations': {'today': 0, 'upcoming': 0},
    'budget': {'target': 0, 'achieved_percent': 0.0},
    'revenue_trends': [],
  };
});
