import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/login_screen.dart';
import 'admin/dashboard_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const OnBoardingScreen();
    } else {
      return const DashboardScreen();
    }
  }
}
