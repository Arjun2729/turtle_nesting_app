//lib/database/start_walk_screen.dart
import 'package:flutter/material.dart';
import 'walk_session_screen.dart';

class StartWalkScreen extends StatelessWidget {
  const StartWalkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Begin Walk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalkSessionScreen()),
              );
            },
            child: const Text('Begin Walk'),
          ),
        ),
      ),
    );
  }
}

