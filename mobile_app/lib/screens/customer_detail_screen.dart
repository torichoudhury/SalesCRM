import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import 'customer_form_screen.dart';
import 'contact_form_screen.dart';
import 'opportunity_form_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;
  const CustomerDetailScreen({super.key, required this.customerId, required this.customerName});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        actions: [
          detailAsync.whenData((customer) => IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CustomerFormScreen(initialData: customer))),
          )).value ?? const SizedBox(),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Contacts'),
            Tab(text: 'Opportunities'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customer) => TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(customer: customer),
            _ContactsTab(customerId: widget.customerId, customer: customer),
            _OpportunitiesTab(customerId: widget.customerId),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> customer;
  const _OverviewTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      customer['type'] == 'Individual' ? Icons.person_rounded : Icons.business_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(customer['type'] ?? 'Company', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatChip(label: '${customer['contacts_count'] ?? 0} Contacts', color: const Color(0xFF6366f1)),
                            const SizedBox(width: 8),
                            _StatChip(label: '${customer['opportunities_count'] ?? 0} Opps', color: const Color(0xFF0ea5e9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoSection(title: 'Contact Information', items: [
            _InfoItem(icon: Icons.email_rounded, label: 'Email', value: customer['email']),
            _InfoItem(icon: Icons.phone_rounded, label: 'Phone', value: customer['phone']),
          ]),
          if (customer['address'] != null || customer['city'] != null) ...[
            const SizedBox(height: 12),
            _InfoSection(title: 'Address', items: [
              _InfoItem(icon: Icons.location_on_rounded, label: 'Address', value: customer['address']),
              _InfoItem(icon: Icons.location_city_rounded, label: 'City', value: customer['city']),
              _InfoItem(icon: Icons.map_rounded, label: 'State', value: customer['state']),
              _InfoItem(icon: Icons.public_rounded, label: 'Country', value: customer['country']),
              _InfoItem(icon: Icons.markunread_mailbox_rounded, label: 'Postcode', value: customer['zipcode']),
            ]),
          ],
          const SizedBox(height: 12),
          _InfoSection(title: 'Account Details', items: [
            _InfoItem(icon: Icons.payment_rounded, label: 'Payment Terms', value: customer['payment_terms']),
            _InfoItem(icon: Icons.receipt_rounded, label: 'Tax ID', value: customer['tax_id']),
          ]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((i) => i.value != null && i.value!.toString().isNotEmpty).toList();
    if (visibleItems.isEmpty) return const SizedBox();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            const SizedBox(height: 12),
            ...visibleItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 10),
                  Text('${item.label}: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Expanded(child: Text(item.value!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoItem({required this.icon, required this.label, this.value});
}

// ─── Contacts Tab ─────────────────────────────────────────────────────────────

class _ContactsTab extends ConsumerWidget {
  final int customerId;
  final Map<String, dynamic> customer;
  const _ContactsTab({required this.customerId, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contactsByCustomerProvider(customerId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (contacts) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Contact'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ContactFormScreen(preselectedCustomerId: customerId))),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? const Center(child: Text('No contacts yet'))
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (_, i) {
                      final c = contacts[i];
                      final name = '${c['first_name']} ${c['last_name'] ?? ''}'.trim();
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(c['designation'] ?? ''),
                        trailing: Text(c['phone'] ?? c['email'] ?? '', style: const TextStyle(fontSize: 12)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ContactFormScreen(initialData: c))),
                      );
                    }),
          ),
        ],
      ),
    );
  }
}

// ─── Opportunities Tab ────────────────────────────────────────────────────────

class _OpportunitiesTab extends ConsumerWidget {
  final int customerId;
  const _OpportunitiesTab({required this.customerId});

  Color _stageColor(String stage) {
    switch (stage) {
      case 'New': return const Color(0xFF3b82f6);
      case 'Qualified': return const Color(0xFF8b5cf6);
      case 'Negotiation': return const Color(0xFFf59e0b);
      case 'Won': return const Color(0xFF22c55e);
      case 'Closed': return const Color(0xFF10b981);
      case 'Lost': return const Color(0xFFef4444);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(opportunitiesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (opps) {
        final filtered = opps.where((o) => o['customer'] == customerId).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Opportunity'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => OpportunityFormScreen(preselectedCustomerId: customerId))),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No opportunities'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final o = filtered[i];
                        final stage = o['stage'] ?? 'New';
                        final color = _stageColor(stage);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            title: Text(o['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${o['number'] ?? ''} • MYR ${o['expected_revenue'] ?? '0.00'}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(stage, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }),
            ),
          ],
        );
      },
    );
  }
}
