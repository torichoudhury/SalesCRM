import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/system_admin_provider.dart';
import 'role_form_screen.dart';
import 'subsidiary_form_screen.dart';

class SystemAdminScreen extends ConsumerStatefulWidget {
  const SystemAdminScreen({super.key});

  @override
  ConsumerState<SystemAdminScreen> createState() => _SystemAdminScreenState();
}

class _SystemAdminScreenState extends ConsumerState<SystemAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Administration'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Roles'),
            Tab(text: 'Subsidiaries'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleFormScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubsidiaryFormScreen()));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRolesTab(),
          _buildSubsidiariesTab(),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    final rolesAsync = ref.watch(rolesProvider);
    return rolesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (roles) {
        if (roles.isEmpty) return const Center(child: Text('No roles found.'));
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(rolesProvider.future),
          child: ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final r = roles[index];
              return ListTile(
                leading: const Icon(Icons.security),
                title: Text(r['name']),
                subtitle: Text(r['description']),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSubsidiariesTab() {
    final subAsync = ref.watch(subsidiariesProvider);
    return subAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (subs) {
        if (subs.isEmpty) return const Center(child: Text('No subsidiaries found.'));
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(subsidiariesProvider.future),
          child: ListView.builder(
            itemCount: subs.length,
            itemBuilder: (context, index) {
              final s = subs[index];
              return ListTile(
                leading: const Icon(Icons.business),
                title: Text(s['name']),
                subtitle: Text('Tax ID: ${s['tax_id']}'),
              );
            },
          ),
        );
      },
    );
  }
}
