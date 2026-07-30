import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import '../services/api_client.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  final int? preselectedCustomerId;

  const ContactFormScreen({super.key, this.initialData, this.preselectedCustomerId});

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _zipcodeController;

  String _designation = 'Main';
  int? _selectedCustomerId;

  final List<String> _designations = ['Main', 'Finance', 'Management', 'Operations', 'Other'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _firstNameController = TextEditingController(text: d?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: d?['last_name'] ?? '');
    _emailController = TextEditingController(text: d?['email'] ?? '');
    _phoneController = TextEditingController(text: d?['phone'] ?? '');
    _addressController = TextEditingController(text: d?['address'] ?? '');
    _cityController = TextEditingController(text: d?['city'] ?? '');
    _stateController = TextEditingController(text: d?['state'] ?? '');
    _countryController = TextEditingController(text: d?['country'] ?? 'Malaysia');
    _zipcodeController = TextEditingController(text: d?['zipcode'] ?? '');
    _designation = d?['designation'] ?? 'Main';
    _selectedCustomerId = d?['customer'] ?? widget.preselectedCustomerId;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      _showError('Please select a customer');
      return;
    }
    setState(() => _isLoading = true);

    final payload = {
      'customer': _selectedCustomerId,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'designation': _designation,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'country': _countryController.text.trim(),
      'zipcode': _zipcodeController.text.trim(),
    };

    try {
      final isEdit = widget.initialData != null;
      final response = isEdit
          ? await apiClient.put('/crm/contacts/${widget.initialData!['id']}/', payload)
          : await apiClient.post('/crm/contacts/', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.invalidate(contactsProvider);
        if (_selectedCustomerId != null) {
          ref.invalidate(contactsByCustomerProvider(_selectedCustomerId!));
        }
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _showAiFillDialog() async {
    final textController = TextEditingController(
      text: "Alice Wong from Acme (alice.w@acme.com) +1-800-555-1234",
    );
    bool dialogLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Contact Smart Fill',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste messy text, email signature, or chat log. AI will extract fields automatically.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Example: Alice Wong from Acme (alice.w@acme.com) +1-800-555-1234",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (dialogLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Analyze & Fill'),
                          onPressed: () async {
                            final rawText = textController.text.trim();
                            if (rawText.isEmpty) return;

                            setModalState(() => dialogLoading = true);

                            try {
                              final response = await apiClient.post('/ai/normalize-contact/', {'text': rawText});
                              if (response.statusCode == 200) {
                                final res = jsonDecode(response.body);
                                if (res != null) {
                                  // Update text fields
                                  final nameParts = (res['name'] ?? '').toString().split(' ');
                                  final first = nameParts.isNotEmpty ? nameParts[0] : '';
                                  final last = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

                                  _firstNameController.text = first;
                                  _lastNameController.text = last;
                                  if (res['email'] != null) _emailController.text = res['email'];
                                  if (res['phone'] != null) _phoneController.text = res['phone'];

                                  // Also try to match customer name if company returned
                                  final company = res['company'];
                                  if (company != null && company.toString().isNotEmpty) {
                                    final customers = ref.read(customersProvider).value ?? [];
                                    final matched = customers.firstWhere(
                                      (c) => c['name'].toString().toLowerCase().contains(company.toString().toLowerCase()),
                                      orElse: () => null,
                                    );
                                    if (matched != null) {
                                      setState(() {
                                        _selectedCustomerId = matched['id'];
                                      });
                                    }
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('AI auto-filled contact fields! ✨'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('AI analysis failed: ${response.body}')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              setModalState(() => dialogLoading = false);
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'New Contact' : 'Edit Contact'),
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
                  if (widget.initialData == null) ...[
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: const Text("AI Smart Fill", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Paste messy details or signatures to fill fields instantly", style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.bolt_rounded, color: Colors.amber),
                        onTap: _showAiFillDialog,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionHeader(title: 'Basic Information'),
                  const SizedBox(height: 12),
                  customersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading customers: $e'),
                    data: (customers) => DropdownButtonFormField<int>(
                      decoration: _decoration('Customer *'),
                      value: _selectedCustomerId,
                      items: customers.map<DropdownMenuItem<int>>((c) =>
                        DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                      onChanged: (val) => setState(() => _selectedCustomerId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _decoration('First Name *'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: _decoration('Last Name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: _decoration('Designation'),
                    value: _designation,
                    items: _designations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _designation = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: _decoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _decoration('Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Address'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: _decoration('Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _cityController, decoration: _decoration('City'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _stateController, decoration: _decoration('State'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _countryController, decoration: _decoration('Country'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _zipcodeController, decoration: _decoration('Postcode'))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(widget.initialData == null ? 'Create Contact' : 'Update Contact',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5)),
    );
  }
}
