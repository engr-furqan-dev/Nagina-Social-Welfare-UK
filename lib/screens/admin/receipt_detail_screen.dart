import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cash_receipt_model.dart';
import '../../providers/cash_receipt_provider.dart';
import '../../services/receipt_pdf_service.dart';

/// Full receipt view: all fields, edit and save to Firestore, re-share PDF.
class ReceiptDetailScreen extends StatefulWidget {
  final String receiptId;
  final CashReceiptModel? fallback;

  const ReceiptDetailScreen({
    super.key,
    required this.receiptId,
    this.fallback,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  static const _titleOptions = [
    'Mr.',
    'Mrs.',
    'Miss',
    'Ms.',
    'Mx.',
    'Dr.',
    'Other',
  ];

  static const _standardTitles = ['Mr.', 'Mrs.', 'Miss', 'Ms.', 'Mx.', 'Dr.'];

  static const _purposeOptions = [
    'Donation',
    'Zakat',
    'Fitrana',
    'Sadqa',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customTitleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customPurposeController = TextEditingController();
  final _receivedByController = TextEditingController();

  bool _isEditing = false;
  String _payeeTitle = 'Mr.';
  String _purpose = 'Donation';
  String _paymentMethod = 'cash';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customTitleController.dispose();
    _amountController.dispose();
    _customPurposeController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  void _hydrateFrom(CashReceiptModel r) {
    _nameController.text = r.payeeName;
    _amountController.text = r.amount.toString();
    _receivedByController.text = r.receivedBy;

    final title = r.payeeTitle.trim();
    if (title.isEmpty || _standardTitles.contains(title)) {
      _payeeTitle = title.isEmpty ? 'Mr.' : title;
      _customTitleController.clear();
    } else {
      _payeeTitle = 'Other';
      _customTitleController.text = title;
    }

    if (_purposeOptions.sublist(0, 4).contains(r.purpose)) {
      _purpose = r.purpose;
      _customPurposeController.clear();
    } else {
      _purpose = 'Other';
      _customPurposeController.text = r.purpose;
    }

    _paymentMethod =
        r.paymentMethod == 'cheque_online' ? 'cheque_online' : 'cash';
    _date = r.date;
  }

  String _effectiveTitle() {
    if (_payeeTitle != 'Other') return _payeeTitle;
    return _customTitleController.text.trim();
  }

  String _effectivePurpose() {
    if (_purpose != 'Other') return _purpose;
    return _customPurposeController.text.trim();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final base = context.read<CashReceiptProvider>().receiptById(widget.receiptId) ??
        widget.fallback;
    if (base == null) return;

    if (!_formKey.currentState!.validate()) return;
    if (_payeeTitle == 'Other' && _customTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter custom title')),
      );
      return;
    }
    if (_purpose == 'Other' && _customPurposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter custom purpose')),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = base.copyWith(
        payeeTitle: _effectiveTitle(),
        payeeName: _nameController.text.trim(),
        amount: amount,
        purpose: _effectivePurpose(),
        date: _date,
        paymentMethod: _paymentMethod,
        receivedBy: _receivedByController.text.trim(),
      );
      await context.read<CashReceiptProvider>().updateReceipt(updated);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share(CashReceiptModel r) async {
    try {
      await ReceiptPdfService.shareReceipt(r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF265d60);
    final provider = context.watch<CashReceiptProvider>();
    final receipt = provider.receiptById(widget.receiptId) ?? widget.fallback;

    if (receipt == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Receipt'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Receipt not found.')),
      );
    }

    final df = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () => _share(receipt),
          ),
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() {
                _isEditing = true;
                _hydrateFrom(receipt);
              }),
              child: const Text('Edit', style: TextStyle(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _isEditing = false;
                        _hydrateFrom(receipt);
                      }),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.receiptId,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Document ID: ${receipt.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text('Created: ${df.format(receipt.createdAt)}'),
                    if (receipt.updatedAt != null)
                      Text('Last updated: ${df.format(receipt.updatedAt!)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              _roTile('Payee', receipt.payeeLine),
              _roTile('Amount', '£${receipt.amount.toStringAsFixed(2)}'),
              _roTile('Purpose', receipt.purpose),
              _roTile(
                'Payment',
                receipt.paymentMethod == 'cheque_online'
                    ? 'Chq. / Online'
                    : 'Cash',
              ),
              _roTile(
                'Receipt date',
                DateFormat('dd MMM yyyy').format(receipt.date),
              ),
              _roTile(
                'Received by',
                receipt.receivedBy.isEmpty ? '—' : receipt.receivedBy,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _share(receipt),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Share PDF again'),
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _payeeTitle,
                decoration: const InputDecoration(labelText: 'Title'),
                items: _titleOptions
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t == 'Other' ? 'Other (custom)' : t),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _payeeTitle = v ?? 'Mr.'),
              ),
              if (_payeeTitle == 'Other')
                TextFormField(
                  controller: _customTitleController,
                  decoration: const InputDecoration(labelText: 'Custom title'),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (£)'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _purpose,
                decoration: const InputDecoration(labelText: 'Purpose'),
                items: _purposeOptions
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _purpose = v ?? 'Donation'),
              ),
              if (_purpose == 'Other')
                TextFormField(
                  controller: _customPurposeController,
                  decoration:
                      const InputDecoration(labelText: 'Custom purpose'),
                ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('Cash')),
                  ButtonSegment(
                    value: 'cheque_online',
                    label: Text('Chq./Online'),
                  ),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (s) =>
                    setState(() => _paymentMethod = s.first),
              ),
              TextFormField(
                controller: _receivedByController,
                decoration: const InputDecoration(labelText: 'Received by'),
              ),
              ListTile(
                title: const Text('Receipt date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save changes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _roTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
