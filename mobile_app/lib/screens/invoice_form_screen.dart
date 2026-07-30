import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import '../services/api_client.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const InvoiceFormScreen({super.key, this.initialData});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  int? _selectedCustomerId;
  String _status = 'Draft';
  DateTime _dateIssued = DateTime.now();
  DateTime? _dueDate;
  double _subtotal = 0;
  double _discount = 0;
  double _total = 0;
  String _remark = '';
  String _memo = '';

  final _statuses = ['Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _selectedCustomerId = d?['customer'];
    _status = d?['status'] ?? 'Draft';
    _subtotal = (d?['subtotal'] as num?)?.toDouble() ?? 0;
    _discount = (d?['discount'] as num?)?.toDouble() ?? 0;
    _total = (d?['total'] as num?)?.toDouble() ?? 0;
    _remark = d?['remark'] ?? '';
    _memo = d?['memo'] ?? '';
    if (d?['date_issued'] != null) _dateIssued = DateTime.tryParse(d!['date_issued']) ?? DateTime.now();
    if (d?['due_date'] != null) _dueDate = DateTime.tryParse(d!['due_date']);
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
      'customer': _selectedCustomerId,
      'status': _status,
      'date_issued': _dateIssued.toIso8601String().split('T')[0],
      'due_date': _dueDate?.toIso8601String().split('T')[0],
      'subtotal': _subtotal,
      'discount': _discount,
      'total': _subtotal - _discount,
      'remark': _remark.isEmpty ? null : _remark,
      'memo': _memo.isEmpty ? null : _memo,
    };

    try {
      final isEdit = widget.initialData != null;
      final response = isEdit
          ? await apiClient.put('/crm/invoices/${widget.initialData!['id']}/', payload)
          : await apiClient.post('/crm/invoices/', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ref.refresh(invoicesProvider.future);
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

  Future<void> _pickDate(bool isDue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? (_dueDate ?? DateTime.now().add(const Duration(days: 30))) : _dateIssued,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isDue ? _dueDate = picked : _dateIssued = picked);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'New Invoice' : widget.initialData!['number'] ?? 'Edit Invoice'),
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
                  _SectionHeader(title: 'Invoice Details'),
                  const SizedBox(height: 12),
                  customersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (customers) => DropdownButtonFormField<int>(
                      decoration: _dec('Customer *'),
                      value: _selectedCustomerId,
                      items: customers.map<DropdownMenuItem<int>>((c) =>
                        DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                      onChanged: (val) => setState(() => _selectedCustomerId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: _dec('Status'),
                    value: _status,
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _DateField(
                      label: 'Date Issued',
                      date: _dateIssued,
                      onTap: () => _pickDate(false),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DateField(
                      label: 'Due Date',
                      date: _dueDate,
                      onTap: () => _pickDate(true),
                    )),
                  ]),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Amounts'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _subtotal.toStringAsFixed(2),
                    decoration: _dec('Subtotal (MYR)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _subtotal = double.tryParse(v) ?? 0),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _discount.toStringAsFixed(2),
                    decoration: _dec('Discount (MYR)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total (MYR)', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'MYR ${(_subtotal - _discount).toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Notes'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _remark,
                    decoration: _dec('Remark'),
                    maxLines: 2,
                    onSaved: (v) => _remark = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _memo,
                    decoration: _dec('Memo (internal)'),
                    maxLines: 2,
                    onSaved: (v) => _memo = v ?? '',
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(widget.initialData == null ? 'Create Invoice' : 'Update Invoice',
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
        ),
        child: Text(
          date != null ? '${date!.day}/${date!.month}/${date!.year}' : 'Select',
          style: TextStyle(color: date != null ? null : Colors.grey),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
        color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5));
  }
}
