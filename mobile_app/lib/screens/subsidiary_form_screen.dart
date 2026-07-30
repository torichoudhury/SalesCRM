import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/system_admin_provider.dart';
import '../services/api_client.dart';

class SubsidiaryFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const SubsidiaryFormScreen({super.key, this.initialData});

  @override
  ConsumerState<SubsidiaryFormScreen> createState() => _SubsidiaryFormScreenState();
}

class _SubsidiaryFormScreenState extends ConsumerState<SubsidiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _address;
  late String _taxId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _name = widget.initialData!['name'];
      _address = widget.initialData!['address'];
      _taxId = widget.initialData!['tax_id'];
    } else {
      _name = '';
      _address = '';
      _taxId = '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    final payload = {
      'name': _name,
      'address': _address,
      'tax_id': _taxId,
    };

    try {
      final response = widget.initialData == null
          ? await apiClient.post('/admin/subsidiaries/', payload)
          : await apiClient.put('/admin/subsidiaries/${widget.initialData!["id"]}/', payload);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ignore: unused_result
        ref.refresh(subsidiariesProvider.future);
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
      appBar: AppBar(title: Text(widget.initialData == null ? 'New Subsidiary' : 'Edit Subsidiary')),
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
                  decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _name = val!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _taxId,
                  decoration: const InputDecoration(labelText: 'Tax ID', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _taxId = val!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _address,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _address = val!,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Save Subsidiary', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
