import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/system_admin_provider.dart';
import '../services/api_client.dart';

class RoleFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const RoleFormScreen({super.key, this.initialData});

  @override
  ConsumerState<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends ConsumerState<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _name = widget.initialData!['name'];
      _description = widget.initialData!['description'];
    } else {
      _name = '';
      _description = '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    final payload = {
      'name': _name,
      'description': _description,
    };

    try {
      final response = widget.initialData == null
          ? await apiClient.post('/admin/roles/', payload)
          : await apiClient.put('/admin/roles/${widget.initialData!["id"]}/', payload);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ignore: unused_result
        ref.refresh(rolesProvider.future);
        if (mounted) Navigator.pop(context);
      } else {
        _showError('Failed: ${response.body}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialData == null ? 'New Role' : 'Edit Role')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Role Name', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _name = val!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  onSaved: (val) => _description = val ?? '',
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Save Role', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
