import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cash_receipt_model.dart';
import '../../providers/cash_receipt_provider.dart';
import 'receipt_detail_screen.dart';

class ReceiptLogScreen extends StatefulWidget {
  const ReceiptLogScreen({super.key});

  @override
  State<ReceiptLogScreen> createState() => _ReceiptLogScreenState();
}

class _ReceiptLogScreenState extends State<ReceiptLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterMonth;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterMonth ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _filterMonth = DateTime(picked.year, picked.month, 1));
    }
  }

  Future<void> _openDetail(CashReceiptModel receipt) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReceiptDetailScreen(
          receiptId: receipt.id,
          fallback: receipt,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF265d60);
    final provider = context.watch<CashReceiptProvider>();
    final receipts = provider.filter(
      query: _searchQuery,
      month: _filterMonth,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Log'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText:
                        'Search: ID, name, amount, date, payment, purpose, received by…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use several words to narrow results (all must match).',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _filterMonth == null
                            ? 'All months'
                            : 'Month: ${DateFormat('MMMM yyyy').format(_filterMonth!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickMonth,
                      child: const Text('Pick month'),
                    ),
                    if (_filterMonth != null)
                      TextButton(
                        onPressed: () => setState(() => _filterMonth = null),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: receipts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _searchQuery.trim().isEmpty
                            ? 'No receipts in this month.'
                            : 'No receipts match your search.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: receipts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      return ListTile(
                        title: Text(
                          receipt.payeeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${receipt.receiptId} · ${DateFormat('dd MMM yyyy').format(receipt.date)} · ${receipt.purpose} · £${receipt.amount.toStringAsFixed(2)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetail(receipt),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
