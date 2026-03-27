import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cash_receipt_model.dart';
import '../../providers/cash_receipt_provider.dart';
import '../../services/receipt_pdf_service.dart';

class GenerateCashReceiptScreen extends StatefulWidget {
  const GenerateCashReceiptScreen({super.key});

  @override
  State<GenerateCashReceiptScreen> createState() =>
      _GenerateCashReceiptScreenState();
}

class ReceiptFormValidators {
  static String? validatePayee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Payee name is required';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }
}

class _GenerateCashReceiptScreenState extends State<GenerateCashReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payeeController = TextEditingController();
  final _customTitleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customPurposeController = TextEditingController();
  final _receivedByController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _payeeTitle = _titleOptions.first;
  String _purpose = _purposeOptions.first;
  String _paymentMethod = 'cash';
  bool _isSaving = false;

  /// Shown on the receipt exactly as selected (e.g. `Mr.`, `Mrs.`).
  static const List<String> _titleOptions = [
    'Mr.',
    'Mrs.',
    'Miss',
    'Ms.',
    'Mx.',
    'Dr.',
    'Other',
  ];

  static const List<String> _purposeOptions = [
    'Donation',
    'Zakat',
    'Fitrana',
    'Sadqa',
    'Other',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _effectiveTitle() {
    if (_payeeTitle != 'Other') return _payeeTitle;
    return _customTitleController.text.trim();
  }

  String _effectivePurpose() {
    if (_purpose != 'Other') return _purpose;
    return _customPurposeController.text.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_payeeTitle == 'Other' && _customTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter custom title (e.g. Prof.)')),
      );
      return;
    }

    if (_purpose == 'Other' && _customPurposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter custom purpose')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<CashReceiptProvider>();
      final amount = double.parse(_amountController.text.trim());
      final docId = await provider.createReceipt(
        payeeName: _payeeController.text.trim(),
        payeeTitle: _effectiveTitle(),
        amount: amount,
        purpose: _effectivePurpose(),
        date: _selectedDate,
        paymentMethod: _paymentMethod,
        receivedBy: _receivedByController.text.trim(),
      );

      final saved = provider.receipts.firstWhere(
        (r) => r.id == docId,
        orElse: () => CashReceiptModel(
          id: docId,
          receiptId: '',
          payeeTitle: _effectiveTitle(),
          payeeName: _payeeController.text.trim(),
          amount: amount,
          purpose: _effectivePurpose(),
          date: _selectedDate,
          createdAt: DateTime.now(),
          paymentMethod: _paymentMethod,
          receivedBy: _receivedByController.text.trim(),
        ),
      );

      await ReceiptPdfService.shareReceipt(saved);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash receipt generated and shared')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _customTitleController.dispose();
    _amountController.dispose();
    _customPurposeController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF265d60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Cash Receipt'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _payeeTitle,
                decoration: const InputDecoration(
                  labelText: 'Title (as on receipt)',
                  helperText: 'Printed exactly as shown before the name',
                ),
                items: _titleOptions
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item == 'Other' ? 'Other (custom)' : item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _payeeTitle = value);
                },
              ),
              if (_payeeTitle == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Custom title',
                    hintText: 'e.g. Prof.',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _payeeController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                ),
                validator: ReceiptFormValidators.validatePayee,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount (£)'),
                validator: ReceiptFormValidators.validateAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _purpose,
                decoration: const InputDecoration(
                  labelText: 'Purpose (as on printed receipt)',
                ),
                items: _purposeOptions
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _purpose = value);
                },
              ),
              if (_purpose == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customPurposeController,
                  decoration: const InputDecoration(
                    labelText: 'Custom purpose',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Payment method'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'cash',
                    label: Text('Cash'),
                    icon: Icon(Icons.money),
                  ),
                  ButtonSegment<String>(
                    value: 'cheque_online',
                    label: Text('Chq./Online'),
                    icon: Icon(Icons.account_balance),
                  ),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (s) {
                  setState(() => _paymentMethod = s.first);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receivedByController,
                decoration: const InputDecoration(
                  labelText: 'Received by (optional)',
                  hintText: 'Name or signature line',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(
                  _isSaving ? 'Generating...' : 'Generate and Share Receipt',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
