import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'TALXOne',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Could not load dashboard', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.refresh(dashboardProvider.future),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => _DashboardContent(data: data, username: authState.username ?? 'User', ref: ref),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String username;
  final WidgetRef ref;

  const _DashboardContent({required this.data, required this.username, required this.ref});

  @override
  Widget build(BuildContext context) {
    final kpis = data['kpis'] as Map<String, dynamic>;
    final crm = data['crm_performance'] as Map<String, dynamic>;
    final sales = data['sales_metrics'] as Map<String, dynamic>;
    final budget = data['budget'] as Map<String, dynamic>;
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(dashboardProvider.future),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome $username,',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_monthName(now.month)} ${now.year}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section label
            _sectionLabel(context, 'Key Performance Indicators'),
            const SizedBox(height: 12),

            // KPI Cards — 2-column grid
            Row(
              children: [
                Expanded(child: _KpiCard(
                  title: 'Total Revenue',
                  value: 'MYR ${_fmt(kpis['total_revenue'])}',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF22c55e),
                  subtitle: 'Gross income',
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  title: 'Outst. Receivables',
                  value: 'MYR ${_fmt(kpis['outstanding_receivables'])}',
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFFf59e0b),
                  subtitle: 'Pending invoices',
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _KpiCard(
                  title: 'Gross Profit',
                  value: 'MYR ${_fmt(kpis['gross_profit'])}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF3b82f6),
                  subtitle: 'Net earnings',
                )),
                const SizedBox(width: 12),
                Expanded(child: _KpiCard(
                  title: 'Budget Target',
                  value: '${budget['achieved_percent']}%',
                  icon: Icons.flag_rounded,
                  color: const Color(0xFFf59e0b),
                  subtitle: 'of MYR ${_fmt(budget['target'])}',
                )),
              ],
            ),

            const SizedBox(height: 24),
            _sectionLabel(context, 'Budget Progress'),
            const SizedBox(height: 12),
            _BudgetProgressCard(budget: budget),

            const SizedBox(height: 24),
            _sectionLabel(context, 'Operations at a Glance'),
            const SizedBox(height: 12),

            // Operations row
            Row(
              children: [
                Expanded(child: _StatTile(
                  icon: Icons.people_alt_rounded,
                  label: 'Customers',
                  value: '${crm['customers']}',
                  color: const Color(0xFF6366f1),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(
                  icon: Icons.handshake_rounded,
                  label: 'Opportunities',
                  value: '${crm['opportunities']}',
                  color: const Color(0xFF06b6d4),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatTile(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Sales Orders',
                  value: '${sales['sales_orders']}',
                  color: const Color(0xFFf59e0b),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(
                  icon: Icons.receipt_long_rounded,
                  label: "Pending Invoices",
                  value: '${sales['pending_invoices']}',
                  color: const Color(0xFF10b981),
                )),
              ],
            ),


          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  String _fmt(dynamic value) {
    final n = (value as num).toDouble();
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toStringAsFixed(0);
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final Map<String, dynamic> budget;

  const _BudgetProgressCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final percent = (budget['achieved_percent'] as num).toDouble() / 100;
    final target = (budget['target'] as num).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Annual Target', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  'MYR ${target >= 1000 ? '${(target / 1000).toStringAsFixed(0)}k' : target.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent > 0.8 ? const Color(0xFF22c55e) : const Color(0xFF3b82f6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${budget['achieved_percent']}% achieved',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}


