import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../providers/crm_provider.dart';
import '../widgets/app_drawer.dart';
import 'contact_form_screen.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';
import 'opportunity_form_screen.dart';
import 'opportunity_detail_screen.dart';
import 'quote_form_screen.dart';
import 'sales_orders_screen.dart';

class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});

  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFabTap() {
    switch (_tabController.index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactFormScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OpportunityFormScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteFormScreen()));
        break;
      case 4:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convert an approved quotation to create one')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Sales CRM', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Customers'),
            Tab(text: 'Opportunities'),
            Tab(text: 'Quotations'),
            Tab(text: 'Sales Orders'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTap,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      })
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContactsTab(searchQuery: _searchQuery),
                _CustomersTab(searchQuery: _searchQuery),
                _OpportunitiesTab(searchQuery: _searchQuery),
                _QuotationsTab(searchQuery: _searchQuery),
                _SalesOrdersTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contacts Tab ─────────────────────────────────────────────────────────────

class _ContactsTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const _ContactsTab({required this.searchQuery});

  @override
  ConsumerState<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends ConsumerState<_ContactsTab> {
  String _viewMode = 'List'; // or 'Card'

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(contactsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorWidget(message: e.toString(), onRetry: () => ref.refresh(contactsProvider.future)),
      data: (items) {
        final filtered = widget.searchQuery.isEmpty
            ? items
            : items.where((c) =>
                (c['first_name'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
                (c['last_name'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
                (c['email'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
                (c['phone'] ?? '').toString().toLowerCase().contains(widget.searchQuery)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  DropdownButton<String>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                    items: const [
                      DropdownMenuItem(value: 'List', child: Text('List View')),
                      DropdownMenuItem(value: 'Card', child: Text('Card View')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState(label: 'No contacts found', icon: Icons.person_outline)
                  : RefreshIndicator(
                      onRefresh: () async => ref.refresh(contactsProvider.future),
                      child: _viewMode == 'Card'
                          ? GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                final fullName = '${c['first_name']} ${c['last_name'] ?? ''}'.trim();
                                final designation = c['designation'] ?? 'Other';
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ContactFormScreen(initialData: c))),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: const Color(0xFF6366f1).withOpacity(0.12),
                                            child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                                style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold, fontSize: 20)),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          _DesignationBadge(designation: designation),
                                          const SizedBox(height: 8),
                                          if (c['email'] != null)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(c['email'],
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                ),
                                              ],
                                            ),
                                          if (c['phone'] != null)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(c['phone'],
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                final fullName = '${c['first_name']} ${c['last_name'] ?? ''}'.trim();
                                final designation = c['designation'] ?? 'Other';
                                final tile = ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF6366f1).withOpacity(0.12),
                                    child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(c['email'] ?? c['phone'] ?? 'No contact info', style: const TextStyle(fontSize: 12)),
                                  trailing: _DesignationBadge(designation: designation),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ContactFormScreen(initialData: c))),
                                );
                                if (index == 0) return tile;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                    tile,
                                  ],
                                );
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DesignationBadge extends StatelessWidget {
  final String designation;
  const _DesignationBadge({required this.designation});

  Color get _color {
    switch (designation) {
      case 'Main': return const Color(0xFF3b82f6);
      case 'Finance': return const Color(0xFF22c55e);
      case 'Management': return const Color(0xFF8b5cf6);
      case 'Operations': return const Color(0xFFf59e0b);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(designation, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Customers Tab ────────────────────────────────────────────────────────────

class _CustomersTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const _CustomersTab({required this.searchQuery});

  @override
  ConsumerState<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<_CustomersTab> {
  String _viewMode = 'List'; // or 'Card'

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(customersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorWidget(message: e.toString(), onRetry: () => ref.refresh(customersProvider.future)),
      data: (items) {
        final filtered = widget.searchQuery.isEmpty
            ? items
            : items.where((c) =>
                (c['name'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
                (c['email'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
                (c['phone'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
                (c['city'] ?? '').toString().toLowerCase().contains(widget.searchQuery)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  DropdownButton<String>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                    items: const [
                      DropdownMenuItem(value: 'List', child: Text('List View')),
                      DropdownMenuItem(value: 'Card', child: Text('Card View')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState(label: 'No customers found', icon: Icons.business_outlined)
                  : RefreshIndicator(
                      onRefresh: () async => ref.refresh(customersProvider.future),
                      child: _viewMode == 'Card'
                          ? GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                final type = c['type'] ?? 'Company';
                                final isCompany = type == 'Company';
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => CustomerDetailScreen(customerId: c['id'], customerName: c['name']))),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: const Color(0xFF0ea5e9).withOpacity(0.12),
                                            child: Icon(isCompany ? Icons.business_rounded : Icons.person_rounded,
                                                color: const Color(0xFF0ea5e9), size: 28),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(c['name'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  c['city'] != null || c['country'] != null
                                                      ? '${c['city'] ?? ''}${c['city'] != null && c['country'] != null ? ', ' : ''}${c['country'] ?? ''}'
                                                      : 'No location',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${c['opportunities_count'] ?? 0} Opps',
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                final tile = ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0ea5e9).withOpacity(0.12),
                                    child: Icon(c['type'] == 'Company' ? Icons.business_rounded : Icons.person_rounded,
                                        color: const Color(0xFF0ea5e9), size: 20),
                                  ),
                                  title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(c['email'] ?? 'No email', style: const TextStyle(fontSize: 12)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${c['opportunities_count'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const Text('opps', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => CustomerDetailScreen(customerId: c['id'], customerName: c['name']))),
                                );
                                if (index == 0) return tile;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                    tile,
                                  ],
                                );
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Opportunities Tab ────────────────────────────────────────────────────────

class _OpportunitiesTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const _OpportunitiesTab({required this.searchQuery});

  @override
  ConsumerState<_OpportunitiesTab> createState() => _OpportunitiesTabState();
}

class _OpportunitiesTabState extends ConsumerState<_OpportunitiesTab> {
  String _selectedStage = 'All';
  String _selectedPriority = 'All';
  String _viewMode = 'List'; // or 'Kanban'

  final _stages = ['All', 'New', 'Qualified', 'Negotiation', 'Won', 'Closed', 'Lost'];
  final _priorities = ['All', 'Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(opportunitiesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorWidget(message: e.toString(), onRetry: () => ref.refresh(opportunitiesProvider.future)),
      data: (items) {
        final filtered = items.where((o) {
          final matchesSearch = widget.searchQuery.isEmpty ||
              (o['title'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
              (o['number'] ?? '').toString().toLowerCase().contains(widget.searchQuery) ||
              (o['customer_name'] ?? '').toString().toLowerCase().contains(widget.searchQuery);
          final matchesStage = _selectedStage == 'All' || o['stage'] == _selectedStage;
          final matchesPriority = _selectedPriority == 'All' || o['priority'] == _selectedPriority;
          return matchesSearch && matchesStage && matchesPriority;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  DropdownButton<String>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                    items: const [
                      DropdownMenuItem(value: 'List', child: Text('List View')),
                      DropdownMenuItem(value: 'Kanban', child: Text('Kanban View')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ],
              ),
            ),
            if (_viewMode == 'Kanban')
              const Expanded(child: _KanbanTab())
            else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Stage: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(width: 8),
                  ..._stages.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          selected: _selectedStage == s,
                          onSelected: (val) => setState(() => _selectedStage = s),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(color: _selectedStage == s ? Theme.of(context).colorScheme.primary : Colors.black87),
                          showCheckmark: false,
                        ),
                      )),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  const Text('Priority: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(width: 8),
                  ..._priorities.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(p, style: const TextStyle(fontSize: 12)),
                          selected: _selectedPriority == p,
                          onSelected: (val) => setState(() => _selectedPriority = p),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(color: _selectedPriority == p ? Theme.of(context).colorScheme.primary : Colors.black87),
                          showCheckmark: false,
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState(label: 'No opportunities found', icon: Icons.handshake_outlined)
                  : RefreshIndicator(
                      onRefresh: () async => ref.refresh(opportunitiesProvider.future),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final o = filtered[index];
                          return _OpportunityCard(opportunity: o);
                        },
                      ),
                    ),
            ),
          ],
        ],
      );
    },
    );
  }
}

// ─── Kanban Tab ───────────────────────────────────────────────────────────────

class _KanbanTab extends ConsumerWidget {
  const _KanbanTab();

  Future<void> _updateStage(WidgetRef ref, BuildContext context, int oppId, String newStage) async {
    try {
      final response = await apiClient.patch(
        '/crm/opportunities/$oppId/',
        {'stage': newStage},
      );
      if (response.statusCode == 200) {
        ref.refresh(opportunitiesKanbanProvider.future);
        ref.refresh(opportunitiesProvider.future);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update stage')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(opportunitiesKanbanProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorWidget(message: e.toString(), onRetry: () => ref.refresh(opportunitiesKanbanProvider.future)),
      data: (data) {
        final stages = ['New', 'Qualified', 'Negotiation', 'Won', 'Closed', 'Lost'];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stages.map((stage) {
              final opps = (data[stage] as List<dynamic>?) ?? [];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DragTarget<Map<String, dynamic>>(
                  onAccept: (opp) {
                    if (opp['stage'] != stage) {
                      _updateStage(ref, context, opp['id'], stage);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(stage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('${opps.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: opps.length,
                            itemBuilder: (context, index) {
                              final opp = opps[index];
                              return LongPressDraggable<Map<String, dynamic>>(
                                data: opp,
                                feedback: SizedBox(
                                  width: 260,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    child: _OpportunityCard(opportunity: opp),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _OpportunityCard(opportunity: opp),
                                ),
                                child: _OpportunityCard(opportunity: opp),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> opportunity;
  const _OpportunityCard({required this.opportunity});

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

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High': return const Color(0xFFef4444);
      case 'Medium': return const Color(0xFFf59e0b);
      case 'Low': return const Color(0xFF22c55e);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = opportunity['stage'] ?? 'New';
    final priority = opportunity['priority'] ?? 'Medium';
    final stageColor = _stageColor(stage);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => OpportunityDetailScreen(opportunity: opportunity))),
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
                        Text(opportunity['number'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(opportunity['title'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                  _StageBadge(stage: stage, color: stageColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      opportunity['customer_name'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.flag_rounded, size: 14, color: _priorityColor(priority)),
                  const SizedBox(width: 4),
                  Text(priority, style: TextStyle(fontSize: 12, color: _priorityColor(priority), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'MYR ${opportunity['expected_revenue'] ?? '0.00'}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (opportunity['expected_closing_date'] != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(opportunity['expected_closing_date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String stage;
  final Color color;
  const _StageBadge({required this.stage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(stage, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Quotations Tab ───────────────────────────────────────────────────────────

class _QuotationsTab extends ConsumerWidget {
  final String searchQuery;
  const _QuotationsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(quotesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorWidget(message: e.toString(), onRetry: () => ref.refresh(quotesProvider.future)),
      data: (items) {
        final filtered = searchQuery.isEmpty
            ? items
            : items.where((q) =>
                (q['number'] ?? '').toString().toLowerCase().contains(searchQuery) ||
                (q['customer_name'] ?? '').toString().toLowerCase().contains(searchQuery) ||
                (q['status'] ?? '').toString().toLowerCase().contains(searchQuery)).toList();
        if (filtered.isEmpty) return const _EmptyState(label: 'No quotations found', icon: Icons.description_outlined);
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(quotesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _QuoteCard(quote: filtered[index]),
          ),
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  const _QuoteCard({required this.quote});

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return const Color(0xFF22c55e);
      case 'Sent': return const Color(0xFF3b82f6);
      case 'Rejected': return const Color(0xFFef4444);
      case 'Expired': return Colors.grey;
      default: return const Color(0xFFf59e0b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = quote['status'] ?? 'Draft';
    final color = _statusColor(status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.description_rounded, color: color, size: 20),
        ),
        title: Row(
          children: [
            Text(quote['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            _StageBadge(stage: status, color: color),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quote['customer_name'] ?? '', style: const TextStyle(fontSize: 13)),
            Text('MYR ${quote['total'] ?? '0.00'}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => QuoteFormScreen(initialData: quote))),
      ),
    );
  }
}

// ─── Sales Orders Tab ─────────────────────────────────────────────────────────

class _SalesOrdersTab extends ConsumerWidget {
  final String searchQuery;
  const _SalesOrdersTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(salesOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorWidget(message: e.toString(), onRetry: () => ref.refresh(salesOrdersProvider.future)),
      data: (items) {
        final filtered = searchQuery.isEmpty
            ? items
            : items.where((s) =>
                (s['number'] ?? '').toString().toLowerCase().contains(searchQuery) ||
                (s['customer_name'] ?? '').toString().toLowerCase().contains(searchQuery) ||
                (s['status'] ?? '').toString().toLowerCase().contains(searchQuery)).toList();
        if (filtered.isEmpty) return const _EmptyState(label: 'No sales orders found', icon: Icons.shopping_bag_outlined);
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(salesOrdersProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _SalesOrderCard(order: filtered[index]),
          ),
        );
      },
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.shopping_bag_rounded, color: color, size: 20),
        ),
        title: Row(
          children: [
            Text(order['number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            _StageBadge(stage: status, color: color),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order['customer_name'] ?? '', style: const TextStyle(fontSize: 13)),
            Text('MYR ${order['total'] ?? '0.00'}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptyState({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Failed to load data'),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}
