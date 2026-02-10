import 'package:flutter/material.dart';
import '../models/collector_model.dart';

class SessionProvider extends ChangeNotifier {
  CollectorModel? _collector;

  CollectorModel? get collector => _collector;

  bool get isLoggedIn => _collector != null;

  void login(CollectorModel collector) {
    _collector = collector;
    notifyListeners();
  }

  void logout() {
    _collector = null;
    notifyListeners();
  }
}
