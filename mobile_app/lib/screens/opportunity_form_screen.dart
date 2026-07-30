import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import '../services/api_client.dart';

class OpportunityFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  final int? preselectedCustomerId;

  const OpportunityFormScreen({super.key, this.initialData, this.preselectedCustomerId});

  @override
  ConsumerState<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends ConsumerState<OpportunityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _remarkController;

  late String _stage;
  late String _priority;
  late String _expectedRevenue;
  int? _selectedCustomerId;
  int? _selectedContactId;
  String _category = '';
  String _referralSource = '';
  String _salesRep = '';
  String _tags = '';
  DateTime? _expectedClosingDate;
  int _winPrediction = 50;

  final _stages = ['New', 'Qualified', 'Negotiation', 'Won', 'Closed', 'Lost'];
  final _priorities = ['Low', 'Medium', 'High'];
  final _categories = ['New Business', 'Existing Business', 'Renewal', 'Upsell', 'Other'];
  final _referralSources = ['Website', 'Referral', 'Cold Call', 'Social Media', 'Event', 'Walk-in', 'Other'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titleController = TextEditingController(text: d?['title'] ?? '');
    _remarkController = TextEditingController(text: d?['remark'] ?? '');
    _stage = d?['stage'] ?? 'New';
    _priority = d?['priority'] ?? 'Medium';
    _expectedRevenue = d?['expected_revenue']?.toString() ?? '0';
    _selectedCustomerId = d?['customer'] ?? widget.preselectedCustomerId;
    _selectedContactId = d?['contact'];
    _category = d?['category'] ?? '';
    _referralSource = d?['referral_source'] ?? '';
    _salesRep = d?['sales_rep'] ?? '';
    _tags = d?['tags'] ?? '';
    _winPrediction = d?['win_prediction'] ?? 50;
    if (d?['expected_closing_date'] != null) {
      _expectedClosingDate = DateTime.tryParse(d!['expected_closing_date']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      _showError('Please select a customer');
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final payload = {
      'title': _titleController.text.trim(),
      'customer': _selectedCustomerId,
      'contact': _selectedContactId,
      'stage': _stage,
      'priority': _priority,
      'expected_revenue': _expectedRevenue,
      'category': _category.isEmpty ? null : _category,
      'referral_source': _referralSource.isEmpty ? null : _referralSource,
      'sales_rep': _salesRep.isEmpty ? null : _salesRep,
      'tags': _tags.isEmpty ? null : _tags,
      'remark': _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      'expected_closing_date': _expectedClosingDate?.toIso8601String().split('T')[0],
      'win_prediction': _winPrediction,
    };

    try {
      final isEdit = widget.initialData != null;
      final response = isEdit
          ? await apiClient.put('/crm/opportunities/${widget.initialData!['id']}/', payload)
          : await apiClient.post('/crm/opportunities/', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.refresh(opportunitiesProvider.future);
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

  Future<void> _autoCategorize() async {
    final titleText = _titleController.text.trim();
    final remarkText = _remarkController.text.trim();
    if (titleText.isEmpty) {
      _showError('Please enter an opportunity title first.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await apiClient.post('/ai/categorize/', {
        'title': titleText,
        'description': remarkText,
      });
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final cat = res['category'] ?? 'Other';
        
        setState(() {
          _category = cat;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI categorized this as: $cat ✨'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('Categorization failed: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedClosingDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expectedClosingDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final contactsAsync = _selectedCustomerId != null
        ? ref.watch(contactsByCustomerProvider(_selectedCustomerId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'New Opportunity' : 'Edit Opportunity'),
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
                  customersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (customers) => DropdownButtonFormField<int>(
                      decoration: _dec('Customer *'),
                      value: _selectedCustomerId,
                      items: customers.map<DropdownMenuItem<int>>((c) =>
                        DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedCustomerId = val;
                        _selectedContactId = null;
                      }),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (contactsAsync != null)
                    contactsAsync.when(
                      loading: () => const SizedBox(),
                      error: (e, _) => const SizedBox(),
                      data: (contacts) => contacts.isEmpty ? const SizedBox() : DropdownButtonFormField<int>(
                        decoration: _dec('Contact'),
                        value: _selectedContactId,
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('-- Select Contact --')),
                          ...contacts.map<DropdownMenuItem<int>>((c) =>
                            DropdownMenuItem(value: c['id'] as int, child: Text('${c['first_name']} ${c['last_name'] ?? ''}'.trim()))),
                        ],
                        onChanged: (val) => setState(() => _selectedContactId = val),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: _dec('Opportunity Title *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Stage
                  _SectionHeader(title: 'Stage & Priority'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _dec('Stage'),
                        value: _stage,
                        items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _stage = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _dec('Priority'),
                        value: _priority,
                        items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _SectionHeader(title: 'Revenue'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _expectedRevenue,
                    decoration: _dec('Expected Revenue (MYR)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _expectedRevenue = v ?? '0',
                  ),
                  const SizedBox(height: 12),

                  // Win Prediction Slider
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Win Probability', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('$_winPrediction%',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          Slider(
                            value: _winPrediction.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (v) => setState(() => _winPrediction = v.toInt()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(title: 'Additional Details'),
                      TextButton.icon(
                        icon: const Icon(Icons.bolt_rounded, size: 14),
                        label: const Text('AI Categorize', style: TextStyle(fontSize: 11)),
                        onPressed: _autoCategorize,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _dec('Category'),
                        value: _category.isEmpty ? null : _category,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('-- None --')),
                          ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _dec('Referral Source'),
                        value: _referralSource.isEmpty ? null : _referralSource,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('-- None --')),
                          ..._referralSources.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                        ],
                        onChanged: (v) => setState(() => _referralSource = v ?? ''),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _salesRep,
                    decoration: _dec('Sales Representative'),
                    onSaved: (v) => _salesRep = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _tags,
                    decoration: _dec('Tags (comma separated)'),
                    onSaved: (v) => _tags = v ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Expected Closing Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: _dec('Expected Closing Date'),
                      child: Text(
                        _expectedClosingDate != null
                            ? '${_expectedClosingDate!.day}/${_expectedClosingDate!.month}/${_expectedClosingDate!.year}'
                            : 'Select date',
                        style: TextStyle(color: _expectedClosingDate != null ? null : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarkController,
                    decoration: _dec('Remark / Notes'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(widget.initialData == null ? 'Create Opportunity' : 'Update Opportunity',
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
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
            color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5));
  }
}
