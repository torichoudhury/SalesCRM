import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import '../services/api_client.dart';

class QuoteFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  final int? opportunityId;
  final int? customerId;

  const QuoteFormScreen({super.key, this.initialData, this.opportunityId, this.customerId});

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  int? _selectedCustomerId;
  int? _selectedContactId;
  int? _selectedOpportunityId;
  String _status = 'Draft';
  String _remark = '';
  double _discount = 0;
  double _charges = 0;

  List<Map<String, dynamic>> _lineItems = [];

  final _statuses = ['Draft', 'Sent', 'Approved', 'Rejected', 'Expired'];

  double _parseAsDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  int _parseAsInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _selectedCustomerId = d?['customer'] ?? widget.customerId;
    _selectedContactId = d?['contact'];
    _selectedOpportunityId = d?['opportunity'] ?? widget.opportunityId;
    _status = d?['status'] ?? 'Draft';
    _remark = d?['remark'] ?? '';
    _discount = _parseAsDouble(d?['discount']);
    _charges = _parseAsDouble(d?['charges']);
    if (d?['line_items'] != null) {
      _lineItems = (d!['line_items'] as List).map<Map<String, dynamic>>((item) => {
        'product': item['product'] ?? '',
        'description': item['description'] ?? '',
        'unit_price': _parseAsDouble(item['unit_price']),
        'pax': _parseAsInt(item['pax'] ?? 1),
        'discount': _parseAsDouble(item['discount']),
        'tax': _parseAsDouble(item['tax']),
      }).toList();
    }
  }

  double get _subtotal => _lineItems.fold(0.0, (sum, item) {
    final unitPrice = _parseAsDouble(item['unit_price']);
    final pax = _parseAsInt(item['pax']);
    final discount = _parseAsDouble(item['discount']);
    return sum + unitPrice * pax * (1 - discount / 100);
  });

  double get _tax => _lineItems.fold(0.0, (sum, item) {
    final unitPrice = _parseAsDouble(item['unit_price']);
    final pax = _parseAsInt(item['pax']);
    final discount = _parseAsDouble(item['discount']);
    final tax = _parseAsDouble(item['tax']);
    final lineSubtotal = unitPrice * pax * (1 - discount / 100);
    return sum + lineSubtotal * (tax / 100);
  });

  double get _total => _subtotal + _tax - _discount + _charges;

  void _addLineItem() {
    setState(() => _lineItems.add({'product': '', 'description': '', 'unit_price': 0.0, 'pax': 1, 'discount': 0.0, 'tax': 0.0}));
  }

  void _removeLineItem(int index) {
    setState(() => _lineItems.removeAt(index));
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
      'contact': _selectedContactId,
      'opportunity': _selectedOpportunityId,
      'status': _status,
      'remark': _remark.isEmpty ? null : _remark,
      'discount': _discount,
      'charges': _charges,
      'subtotal': _subtotal,
      'tax': _tax,
      'total': _total,
    };

    try {
      final isEdit = widget.initialData != null;
      final response = isEdit
          ? await apiClient.put('/crm/quotes/${widget.initialData!['id']}/', payload)
          : await apiClient.post('/crm/quotes/', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final savedQuote = jsonDecode(response.body);
        final quoteId = savedQuote['id'];

        // Save line items
        for (final item in _lineItems) {
          await apiClient.post('/crm/quote-line-items/', {...item, 'quote': quoteId});
        }

        ref.refresh(quotesProvider.future);
        ref.refresh(salesOrdersProvider.future);
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

  Future<void> _convertToSalesOrder() async {
    if (widget.initialData == null) return;
    try {
      final response = await apiClient.post('/crm/quotes/${widget.initialData!['id']}/convert_to_sales_order/', {});
      if (response.statusCode == 201) {
        ref.refresh(salesOrdersProvider.future);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Converted to Sales Order!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'New Quotation' : widget.initialData!['number'] ?? 'Edit Quotation'),
        actions: [
          if (widget.initialData != null && widget.initialData!['status'] == 'Approved')
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Convert to Sales Order',
              onPressed: _convertToSalesOrder,
            ),
          if (_status != 'Approved')
            TextButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              label: const Text('Approve', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                setState(() => _status = 'Approved');
                await _submit();
              },
            ),
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
                  _SectionHeader(title: 'Customer & Status'),
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
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(title: 'Line Items'),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Item'),
                        onPressed: _addLineItem,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_lineItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('No items added yet', style: TextStyle(color: Colors.grey))),
                    ),

                  ...List.generate(_lineItems.length, (i) => _LineItemCard(
                    index: i,
                    item: _lineItems[i],
                    onRemove: () => _removeLineItem(i),
                    onChanged: (updated) => setState(() => _lineItems[i] = updated),
                  )),

                  const SizedBox(height: 16),

                  // Totals
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _TotalRow(label: 'Subtotal', value: 'MYR ${_subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _TotalRow(label: 'Tax', value: 'MYR ${_tax.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Discount (MYR):', style: TextStyle(color: Colors.grey)),
                              const Spacer(),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  initialValue: _discount.toStringAsFixed(2),
                                  decoration: _dec('').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Charges (MYR):', style: TextStyle(color: Colors.grey)),
                              const Spacer(),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  initialValue: _charges.toStringAsFixed(2),
                                  decoration: _dec('').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(() => _charges = double.tryParse(v) ?? 0),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          _TotalRow(
                            label: 'Total',
                            value: 'MYR ${_total.toStringAsFixed(2)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: _remark,
                    decoration: _dec('Remark / Notes'),
                    maxLines: 3,
                    onSaved: (v) => _remark = v ?? '',
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(widget.initialData == null ? 'Create Quotation' : 'Update Quotation',
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

class _LineItemCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final Function(Map<String, dynamic>) onChanged;

  const _LineItemCard({required this.index, required this.item, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: onRemove),
              ],
            ),
            _ItemField('Product / Service *', item['product'] ?? '', (v) => onChanged({...item, 'product': v})),
            _ItemField('Description', item['description'] ?? '', (v) => onChanged({...item, 'description': v})),
            Row(
              children: [
                Expanded(child: _NumField('Unit Price', item['unit_price']?.toString() ?? '0', (v) => onChanged({...item, 'unit_price': double.tryParse(v) ?? 0}))),
                const SizedBox(width: 8),
                Expanded(child: _NumField('Qty/Pax', item['pax']?.toString() ?? '1', (v) => onChanged({...item, 'pax': int.tryParse(v) ?? 1}))),
                const SizedBox(width: 8),
                Expanded(child: _NumField('Disc %', item['discount']?.toString() ?? '0', (v) => onChanged({...item, 'discount': double.tryParse(v) ?? 0}))),
                const SizedBox(width: 8),
                Expanded(child: _NumField('Tax %', item['tax']?.toString() ?? '0', (v) => onChanged({...item, 'tax': double.tryParse(v) ?? 0}))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ItemField(String label, String initial, Function(String) onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          isDense: true,
        ),
        onChanged: onSaved,
      ),
    );
  }

  Widget _NumField(String label, String initial, Function(String) onChanged) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? null : Colors.grey)),
        Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
            color: bold ? Theme.of(context).colorScheme.primary : null)),
      ],
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
