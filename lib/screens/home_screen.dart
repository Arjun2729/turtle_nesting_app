//lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'volunteers_screen.dart';
import '../database/google_sheets_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  Timer? _summaryTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _summaryTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      try {
        await GoogleSheetsService().updateSummarySheet();
      } catch (e) {
        print("Error during periodic summary update: $e");
      }
    });
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen())
    );
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turtle Nesting App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, $_userName', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VolunteersScreen()),
                );
              },
              child: const Text('Record Event'),
            ),
          ],
        ),
      ),
    );
  }
}
