import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/box_provider.dart';
import 'providers/collection_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_gate.dart';
import 'screens/onboarding_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BoxProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
      ],
      child: const CharityCollection(),
    ),
  );
}

class CharityCollection extends StatelessWidget {
  const CharityCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Charity Collection',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),

      home: const SplashScreen(),
      /*FutureBuilder(
        future: Future.delayed(
          const Duration(seconds: 1),
        ), // Simulate initialization
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const OnBoardingScreen();
          } else {
            return const SplashScreen();
          }
        },
      ),

       */

    );
  }
}
