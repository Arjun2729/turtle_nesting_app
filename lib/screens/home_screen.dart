// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'query_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _startNewWalk(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openQueryScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QueryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turtle Nesting App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _startNewWalk(context),
              child: const Text('Start New Walk'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openQueryScreen(context),
              child: const Text('Query & Export Data'),
            ),
          ],
        ),
      ),
    );
  }
}
