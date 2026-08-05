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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Confirmed': return Icons.check_circle_rounded;
      case 'Delivered': return Icons.local_shipping_rounded;
      case 'Cancelled': return Icons.cancel_rounded;
      default: return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'Draft';
    final color = _statusColor(status);
    final createdAt = order['created_at']?.toString().split('T')[0] ?? '';
    final quoteNumber = order['quote_number']?.toString();
    final itemCount = order['item_count'];
    final deliveryAddress = order['delivery_address']?.toString();
    final remark = order['remark']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(status), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['number'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order['customer_name'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Stats Row ────────────────────────────────────────
            Row(
              children: [
                _OrderStat(
                  icon: Icons.payments_rounded,
                  label: 'Total',
                  value: 'MYR ${order['total'] ?? '0.00'}',
                  valueColor: Theme.of(context).colorScheme.primary,
                ),
                if (quoteNumber != null) ...[
                  const _StatDivider(),
                  _OrderStat(
                    icon: Icons.description_rounded,
                    label: 'From Quote',
                    value: quoteNumber,
                  ),
                ],
                if (itemCount != null) ...[
                  const _StatDivider(),
                  _OrderStat(
                    icon: Icons.inventory_2_rounded,
                    label: 'Items',
                    value: itemCount.toString(),
                  ),
                ],
                const _StatDivider(),
                _OrderStat(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: createdAt,
                ),
              ],
            ),

            // ── Bottom strip (address / remark) ──────────────────
            if (deliveryAddress != null && deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deliveryAddress,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (remark != null && remark.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        remark,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _OrderStat({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: Colors.grey),
              const SizedBox(width: 3),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.withOpacity(0.2),
    );
  }
}
