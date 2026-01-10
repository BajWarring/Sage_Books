import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sage_books/login_page.dart';
import 'package:sage_books/home_page.dart'; // Import HomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sage Books',
      theme: ThemeData(
        // Add your theme data here if needed
      ),
      // --- AUTH PERSISTENCE LOGIC ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 2. User is Logged In -> Go to Home
          if (snapshot.hasData) {
            return HomePage(user: snapshot.data!);
          }

          // 3. User is Logged Out -> Go to Login
          return const LoginPage();
        },
      ),
    );
  }
}
