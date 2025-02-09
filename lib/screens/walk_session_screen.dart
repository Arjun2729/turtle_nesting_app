//lib/screens/walk_session_screens.dart
import 'package:flutter/material.dart';
import 'event_form_screen.dart';

class WalkSessionScreen extends StatelessWidget {
  const WalkSessionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Event to Record'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimizes vertical space usage
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventFormScreen(eventType: 'Dead Turtle'),
                  ),
                );
              },
              child: const Text('Dead Turtle'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventFormScreen(eventType: 'False Crawl'),
                  ),
                );
              },
              child: const Text('False Crawl'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventFormScreen(eventType: 'Nest Find'),
                  ),
                );
              },
              child: const Text('Nest Find'),
            ),
          ],
        ),
      ),
    );
  }
}

