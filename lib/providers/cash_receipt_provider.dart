import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cash_receipt_model.dart';
import '../services/firebase_service.dart';
import '../utils/cash_receipt_query.dart';

abstract class CashReceiptDataSource {
  Stream<List<CashReceiptModel>> getCashReceiptsStream();

  Future<String> addCashReceipt({
    required String payeeName,
    String payeeTitle = '',
    required double amount,
    required String purpose,
    required DateTime date,
    String paymentMethod = 'cash',
    String receivedBy = '',
  });

  Future<void> updateCashReceipt(CashReceiptModel receipt);
}

class FirebaseCashReceiptDataSource implements CashReceiptDataSource {
  final FirebaseService _service;

  FirebaseCashReceiptDataSource(this._service);

  @override
  Stream<List<CashReceiptModel>> getCashReceiptsStream() {
    return _service.getCashReceiptsStream();
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
  }) {
    return _service.addCashReceipt(
      payeeName: payeeName,
      payeeTitle: payeeTitle,
      amount: amount,
      purpose: purpose,
      date: date,
      paymentMethod: paymentMethod,
      receivedBy: receivedBy,
    );
  }

  @override
  Future<void> updateCashReceipt(CashReceiptModel receipt) {
    return _service.updateCashReceipt(receipt);
  }
}

class CashReceiptProvider extends ChangeNotifier {
  final CashReceiptDataSource _dataSource;
  StreamSubscription<List<CashReceiptModel>>? _subscription;
  List<CashReceiptModel> _receipts = [];

  CashReceiptProvider({
    CashReceiptDataSource? dataSource,
  }) : _dataSource = dataSource ?? FirebaseCashReceiptDataSource(FirebaseService()) {
    _subscription = _dataSource.getCashReceiptsStream().listen((items) {
      _receipts = items;
      notifyListeners();
    });
  }

  List<CashReceiptModel> get receipts => _receipts;

  Future<String> createReceipt({
    required String payeeName,
    String payeeTitle = '',
    required double amount,
    required String purpose,
    required DateTime date,
    String paymentMethod = 'cash',
    String receivedBy = '',
  }) {
    return _dataSource.addCashReceipt(
      payeeName: payeeName,
      payeeTitle: payeeTitle,
      amount: amount,
      purpose: purpose,
      date: date,
      paymentMethod: paymentMethod,
      receivedBy: receivedBy,
    );
  }

  Future<void> updateReceipt(CashReceiptModel receipt) {
    return _dataSource.updateCashReceipt(receipt);
  }

  CashReceiptModel? receiptById(String id) {
    for (final r in _receipts) {
      if (r.id == id) return r;
    }
    return null;
  }

  double monthlyTotal({DateTime? month}) {
    final pivot = month ?? DateTime.now();
    return _receipts
        .where(
          (r) => r.date.year == pivot.year && r.date.month == pivot.month,
        )
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  List<CashReceiptModel> filter({
    String query = '',
    DateTime? month,
  }) {
    return _receipts.where((receipt) {
      if (!cashReceiptMatchesSearch(receipt, query)) return false;
      if (month == null) return true;
      return receipt.date.year == month.year && receipt.date.month == month.month;
    }).toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
