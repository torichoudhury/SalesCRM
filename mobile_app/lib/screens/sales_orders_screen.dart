import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';

class SalesOrdersScreen extends ConsumerWidget {
  const SalesOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(salesOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Failed to load sales orders'),
              TextButton.icon(
                onPressed: () => ref.refresh(salesOrdersProvider.future),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No sales orders yet', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Convert an approved quotation to create one',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(salesOrdersProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _SalesOrderCard(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SalesOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _SalesOrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed': return const Color(0xFF22c55e);
      case 'Delivered': return const Color(0xFF10b981);
      case 'Cancelled': return const Color(0xFFef4444);
      default: return const Color(0xFFf59e0b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'Draft';
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shopping_bag_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(order['customer_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('MYR ${order['total'] ?? '0.00'}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                if (order['quote_number'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('From Quote', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(order['quote_number'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                Text(
                  order['created_at']?.toString().split('T')[0] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
