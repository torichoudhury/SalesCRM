import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import 'invoice_form_screen.dart';

class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivables', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'AR Ageing'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InvoicesTab(),
          _ArAgeingTab(),
        ],
      ),
    );
  }
}

class _InvoicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return invoicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            TextButton.icon(
              onPressed: () => ref.refresh(invoicesProvider.future),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const Center(child: Text('No invoices found', style: TextStyle(color: Colors.grey)));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(invoicesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: invoices.length,
            itemBuilder: (context, index) => _InvoiceCard(invoice: invoices[index]),
          ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceCard({required this.invoice});

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid': return const Color(0xFF22c55e);
      case 'Overdue': return const Color(0xFFef4444);
      case 'Sent': return const Color(0xFF3b82f6);
      case 'Cancelled': return Colors.grey;
      default: return const Color(0xFFf59e0b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] ?? 'Draft';
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(invoice['customer_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                Text('MYR ${invoice['total'] ?? '0.00'}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                        color: Theme.of(context).colorScheme.primary)),
                if (invoice['due_date'] != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Due: ${invoice['due_date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArAgeingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageingAsync = ref.watch(arAgeingProvider);

    return ageingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            TextButton.icon(
              onPressed: () => ref.refresh(arAgeingProvider.future),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (ageing) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AR Ageing Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Outstanding invoices by overdue period',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            _AgeingCard(label: 'Current', value: ageing['current'] ?? '0.00', color: const Color(0xFF22c55e)),
            const SizedBox(height: 10),
            _AgeingCard(label: '1 – 30 Days Overdue', value: ageing['1_30'] ?? '0.00', color: const Color(0xFFf59e0b)),
            const SizedBox(height: 10),
            _AgeingCard(label: '31 – 60 Days Overdue', value: ageing['31_60'] ?? '0.00', color: const Color(0xFFf97316)),
            const SizedBox(height: 10),
            _AgeingCard(label: '61 – 90 Days Overdue', value: ageing['61_90'] ?? '0.00', color: const Color(0xFFef4444)),
            const SizedBox(height: 10),
            _AgeingCard(label: '> 90 Days Overdue', value: ageing['over_90'] ?? '0.00', color: const Color(0xFF7f1d1d)),
          ],
        ),
      ),
    );
  }
}

class _AgeingCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AgeingCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
            Text('MYR $value',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }
}
