import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'walk_session_screen.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});
  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  final TextEditingController _volunteersCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    final prefs = await SharedPreferences.getInstance();
    String? volunteers = prefs.getString('volunteers');
    if (volunteers != null) {
      _volunteersCtrl.text = volunteers;
    }
  }

  Future<void> _saveAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('volunteers', _volunteersCtrl.text.trim());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WalkSessionScreen()),
    );
  }

  @override
  void dispose() {
    _volunteersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Volunteers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Please confirm the volunteer names for this walk:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _volunteersCtrl,
              decoration: const InputDecoration(
                labelText: 'Volunteers (comma-separated)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAndProceed,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
