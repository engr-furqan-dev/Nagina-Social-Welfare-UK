import 'package:flutter/material.dart';
import '../models/collection_model.dart';

class CollectionProvider extends ChangeNotifier {
  final List<CollectionModel> _collections = [];

  List<CollectionModel> get collections => _collections;

  void setCollections(List<CollectionModel> data) {
    _collections.clear();
    _collections.addAll(data);
    notifyListeners();
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return _collections
        .where((c) =>
    c.date.month == now.month && c.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  DateTime? get lastCollectionDate {
    if (_collections.isEmpty) return null;
    _collections.sort((a, b) => b.date.compareTo(a.date));
    return _collections.first.date;
  }

  double get totalToday {
    final now = DateTime.now();
    return _collections
        .where((c) =>
    c.date.year == now.year &&
        c.date.month == now.month &&
        c.date.day == now.day)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  double totalForBox(String boxId) {
    return _collections
        .where((c) => c.boxId == boxId)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  double monthlyTotalForBox(String boxId, {int? month, int? year}) {
    final now = DateTime.now();
    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    return _collections
        .where((c) =>
    c.boxId == boxId &&
        c.date.year == selectedYear &&
        c.date.month == selectedMonth)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  List<CollectionModel> historyForBox(String boxId) {
    final list = _collections
        .where((c) => c.boxId == boxId)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  Map<String, double> monthlyTotals() {
    final Map<String, double> result = {};

    for (final c in _collections) {
      final key =
          "${c.date.year}-${c.date.month.toString().padLeft(2, '0')}";
      result[key] = (result[key] ?? 0) + c.amount;
    }

    return result;
  }

  CollectionModel? get lastCollection {
    if (_collections.isEmpty) return null;

    // Sort by date descending
    final sorted = List<CollectionModel>.from(_collections)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sorted.first;
  }


}
