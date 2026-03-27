import 'dart:async';
import 'package:flutter/material.dart';
import '../models/box_model.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class BoxProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController searchController = TextEditingController();
  
  List<BoxModel> _boxes = [];
  String _searchQuery = '';
  Timer? _debounce;
  StreamSubscription<List<BoxModel>>? _subscription;

  BoxProvider() {
    _initStream();
  }

  void _initStream() {
    _subscription = _firebaseService.getBoxesStream().listen((list) {
      setBoxes(list);
    });
  }

  List<BoxModel> get boxes {
    if (_searchQuery.isEmpty) return _boxes;
    return _boxes.where((b) =>
      b.boxSequence.toString().padLeft(3, '0').contains(_searchQuery) ||
      b.venueName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  String get searchQuery => _searchQuery;

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value.trim();
      notifyListeners();
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    searchController.clear();
    _searchQuery = '';
    notifyListeners();
  }

  // 🔐 ATOMIC SEQUENCE
  Future<int> _getNextBoxSequence() async {
    final firestore = FirebaseFirestore.instance;
    final counterRef = firestore.collection('meta').doc('counters');

    return await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int current = snapshot.exists ? (snapshot.get('boxSequence') ?? 0) : 0;
      final next = current + 1;
      transaction.set(counterRef, {'boxSequence': next}, SetOptions(merge: true));
      return next;
    });
  }

  Future<BoxModel> addBox(BoxModel box) async {
    final sequence = await _getNextBoxSequence();
    final boxWithSeq = box.copyWith(boxSequence: sequence);
    final docId = await _firebaseService.addBox(boxWithSeq);
    return boxWithSeq.copyWith(id: docId);
  }

  Stream<List<BoxModel>> getBoxesStream() => _firebaseService.getBoxesStream();

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  bool _isNewMonth(DateTime completedAt) {
    final now = DateTime.now();
    final completedMonth = DateTime(completedAt.year, completedAt.month);
    final currentMonth = DateTime(now.year, now.month);
    return currentMonth.isAfter(completedMonth);
  }

  void evaluateBox(BoxModel box) {
    if (box.status == BoxStatus.sentReceipt &&
        box.completedAt != null &&
        _isNewMonth(box.completedAt!)) {
      
      // We don't modify the object here anymore to avoid stream conflicts.
      // Instead, we just trigger a Firebase update if needed.
      _firebaseService.updateBoxStatus(box.boxId, BoxStatus.notCollected);
    }
  }

  void setBoxes(List<BoxModel> list) {
    // We only call evaluateBox here, but the list itself comes from the stream
    for (final box in list) {
      evaluateBox(box);
    }
    _boxes = list;
    notifyListeners();
  }

  // ✅ UPDATE BOX (CENTRALIZED)
  Future<void> updateBox(BoxModel updatedBox) async {
    // Only update Firebase. The stream will automatically update local _boxes.
    await _firebaseService.updateBox(updatedBox);
  }

  void resetAllBoxesLocally() {
    // This is useful for immediate UI feedback before stream updates
    _boxes = _boxes.map((box) => box.copyWith(
      status: BoxStatus.notCollected,
      updatedAt: DateTime.now(),
    )).toList();
    notifyListeners();
  }
}
