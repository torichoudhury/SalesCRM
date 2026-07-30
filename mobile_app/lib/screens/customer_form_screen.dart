import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import '../services/api_client.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const CustomerFormScreen({super.key, this.initialData});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late String _name;
  String _type = 'Company';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _city = '';
  String _state = '';
  String _country = 'Malaysia';
  String _zipcode = '';
  String _paymentTerms = '';
  String _taxId = '';

  final _types = ['Company', 'Individual'];
  final _paymentTermsList = ['COD', '7 Days', '15 Days', '30 Days', '45 Days', '60 Days', '90 Days'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _name = d?['name'] ?? '';
    _type = d?['type'] ?? 'Company';
    _email = d?['email'] ?? '';
    _phone = d?['phone'] ?? '';
    _address = d?['address'] ?? '';
    _city = d?['city'] ?? '';
    _state = d?['state'] ?? '';
    _country = d?['country'] ?? 'Malaysia';
    _zipcode = d?['zipcode'] ?? '';
    _paymentTerms = d?['payment_terms'] ?? '';
    _taxId = d?['tax_id'] ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final payload = {
      'name': _name,
      'type': _type,
      'email': _email.isEmpty ? null : _email,
      'phone': _phone.isEmpty ? null : _phone,
      'address': _address.isEmpty ? null : _address,
      'city': _city.isEmpty ? null : _city,
      'state': _state.isEmpty ? null : _state,
      'country': _country,
      'zipcode': _zipcode.isEmpty ? null : _zipcode,
      'payment_terms': _paymentTerms.isEmpty ? null : _paymentTerms,
      'tax_id': _taxId.isEmpty ? null : _taxId,
    };

    try {
      final isEdit = widget.initialData != null;
      final response = isEdit
          ? await apiClient.put('/crm/customers/${widget.initialData!['id']}/', payload)
          : await apiClient.post('/crm/customers/', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.refresh(customersProvider.future);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showError('Save failed: ${response.body}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'New Customer' : 'Edit Customer'),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _submit, child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader(title: 'Basic Information'),
                  const SizedBox(height: 12),

                  // Type toggle
                  Row(
                    children: [
                      const Text('Type:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      ..._types.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: _name,
                    decoration: _dec('Customer Name *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onSaved: (v) => _name = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _email,
                    decoration: _dec('Email'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (v) => _email = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _phone,
                    decoration: _dec('Phone'),
                    keyboardType: TextInputType.phone,
                    onSaved: (v) => _phone = v ?? '',
                  ),

                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Address'),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: _address,
                    decoration: _dec('Address'),
                    maxLines: 2,
                    onSaved: (v) => _address = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(initialValue: _city, decoration: _dec('City'), onSaved: (v) => _city = v ?? '')),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(initialValue: _state, decoration: _dec('State'), onSaved: (v) => _state = v ?? '')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(initialValue: _country, decoration: _dec('Country'), onSaved: (v) => _country = v ?? 'Malaysia')),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(initialValue: _zipcode, decoration: _dec('Postcode'), onSaved: (v) => _zipcode = v ?? '')),
                  ]),

                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Account Information'),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    decoration: _dec('Payment Terms'),
                    value: _paymentTerms.isEmpty ? null : _paymentTerms,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('-- Select --')),
                      ..._paymentTermsList.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (v) => setState(() => _paymentTerms = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _taxId,
                    decoration: _dec('Tax ID / SST Number'),
                    onSaved: (v) => _taxId = v ?? '',
                  ),

                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(widget.initialData == null ? 'Create Customer' : 'Update Customer',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5));
  }
}
