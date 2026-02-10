import 'dart:async';
import 'package:flutter/material.dart';
import '../models/box_model.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class BoxProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  final TextEditingController searchController = TextEditingController(); // ✅ ADD

  List<BoxModel> _boxes = [];
  String _searchQuery = '';
  Timer? _debounce;

  // Filtered boxes based on search query
  List<BoxModel> get boxes {
    if (_searchQuery.isEmpty) return _boxes;

    return _boxes
        .where((b) =>
        b.boxId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            b.venueName.toLowerCase().contains(_searchQuery.toLowerCase())


    ) // anywhere match
        .toList();
  }

  /*void setBoxes(List<BoxModel> list) {
    _boxes = list;
    notifyListeners();
  }
*/
  // Debounce search input
  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value.trim();
      notifyListeners();
    });
  }

  // ✅ FIXED: clears BOTH state and TextField
  void clearSearch() {
    _debounce?.cancel();
    searchController.clear(); // ✅ clears search bar
    _searchQuery = '';
    notifyListeners();
  }

  String get searchQuery => _searchQuery;

  // 🔐 ATOMIC SEQUENCE
  Future<int> _getNextBoxSequence() async {
    final firestore = FirebaseFirestore.instance;
    final counterRef = firestore.collection('meta').doc('counters');

    return await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      // Get current counter
      int current = snapshot.exists ? (snapshot.get('boxSequence') ?? 0) : 0;

      // Check if any boxes exist
      final boxSnapshot = await firestore.collection('boxes').get();
      if (boxSnapshot.docs.isEmpty) {
        current = 0; // reset sequence if no boxes
      }

      final next = current + 1;

      transaction.set(
        counterRef,
        {'boxSequence': next},
        SetOptions(merge: true),
      );

      return next;
    });
  }


  // ✅ ADD BOX (PRODUCTION SAFE)
  Future<BoxModel> addBox(BoxModel box) async {
    final sequence = await _getNextBoxSequence();

    final newBox = box.copyWith(
      boxSequence: sequence,
    );

    await _firebaseService.addBox(newBox);
    return newBox; // ✅ THIS LINE FIXES EVERYTHING
  }

  // Stream
  Stream<List<BoxModel>> getBoxesStream() {
    return _firebaseService.getBoxesStream();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool _isNewMonth(DateTime completedAt) {
    final now = DateTime.now();

    final completedMonth =
    DateTime(completedAt.year, completedAt.month);
    final currentMonth =
    DateTime(now.year, now.month);

    return currentMonth.isAfter(completedMonth);
  }
  void evaluateBox(BoxModel box) {
    if (box.status == BoxStatus.sentReceipt &&
        box.completedAt != null &&
        _isNewMonth(box.completedAt!)) {

      box.status = BoxStatus.notCollected;
      box.completedAt = null;

      FirebaseService().updateBox(box);
    }
  }
  void setBoxes(List<BoxModel> list) {
    for (final box in list) {
      evaluateBox(box);
    }
    _boxes = list;
    notifyListeners();
  }
// box_provider.dart
  void resetAllBoxesLocally() {
    final updated = boxes.map((box) {
      return box.copyWith(
        status: BoxStatus.notCollected,
        updatedAt: DateTime.now(),
      );
    }).toList();

    setBoxes(updated);
  }



}
