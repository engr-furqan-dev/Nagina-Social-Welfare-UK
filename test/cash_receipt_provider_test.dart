import 'dart:async';

import 'package:charity_collection_app/models/cash_receipt_model.dart';
import 'package:charity_collection_app/providers/cash_receipt_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCashReceiptDataSource implements CashReceiptDataSource {
  final _controller = StreamController<List<CashReceiptModel>>.broadcast();
  List<CashReceiptModel> _items = [];

  void emit(List<CashReceiptModel> items) {
    _items = items;
    _controller.add(items);
  }

  @override
  Future<String> addCashReceipt({
    required String payeeName,
    String payeeTitle = '',
    required double amount,
    required String purpose,
    required DateTime date,
    String paymentMethod = 'cash',
    String receivedBy = '',
  }) async {
    final id = 'doc_${_items.length + 1}';
    final receipt = CashReceiptModel(
      id: id,
      receiptId: 'CR-202603-000${_items.length + 1}',
      payeeTitle: payeeTitle,
      payeeName: payeeName,
      amount: amount,
      purpose: purpose,
      date: date,
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      receivedBy: receivedBy,
    );
    _items = [receipt, ..._items];
    _controller.add(_items);
    return id;
  }

  @override
  Future<void> updateCashReceipt(CashReceiptModel receipt) async {
    _items = _items.map((r) => r.id == receipt.id ? receipt : r).toList();
    _controller.add(_items);
  }

  @override
  Stream<List<CashReceiptModel>> getCashReceiptsStream() => _controller.stream;
}

void main() {
  test('monthlyTotal sums only selected month and filter works', () async {
    final fake = _FakeCashReceiptDataSource();
    final provider = CashReceiptProvider(dataSource: fake);
    addTearDown(provider.dispose);

    fake.emit([
      CashReceiptModel(
        id: '1',
        receiptId: 'CR-202603-0001',
        payeeName: 'Ali',
        amount: 100,
        purpose: 'Zakat',
        date: DateTime(2026, 3, 2),
        createdAt: DateTime(2026, 3, 2),
      ),
      CashReceiptModel(
        id: '2',
        receiptId: 'CR-202603-0002',
        payeeName: 'Umar',
        amount: 75,
        purpose: 'Sadaqah',
        date: DateTime(2026, 3, 12),
        createdAt: DateTime(2026, 3, 12),
      ),
      CashReceiptModel(
        id: '3',
        receiptId: 'CR-202602-0001',
        payeeName: 'Zaid',
        amount: 50,
        purpose: 'Donation',
        date: DateTime(2026, 2, 27),
        createdAt: DateTime(2026, 2, 27),
      ),
    ]);

    await Future<void>.delayed(Duration.zero);

    expect(provider.monthlyTotal(month: DateTime(2026, 3, 1)), 175);
    expect(provider.monthlyTotal(month: DateTime(2026, 2, 1)), 50);

    final filtered = provider.filter(query: 'umar', month: DateTime(2026, 3, 1));
    expect(filtered.length, 1);
    expect(filtered.first.receiptId, 'CR-202603-0002');
  });
}
