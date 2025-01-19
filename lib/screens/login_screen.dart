// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/firebase_service.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _walkType = 'Bessie';
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaults();
  }

  void _setDefaults() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    _startDateCtrl.text = DateFormat('yyyy-MM-dd').format(now);
    _endDateCtrl.text = DateFormat('yyyy-MM-dd').format(tomorrow);
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _startWalk() async {
    if (_startDateCtrl.text.isEmpty || _endDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }
    // pass walkType, startDate, endDate
    final walkData = {
      'walkType': _walkType,
      'startDate': _startDateCtrl.text,
      'endDate': _endDateCtrl.text,
    };

    try {
      final docId = await FirebaseService().createWalk(walkData);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MapScreen(walkDocId: docId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting walk: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a Walk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Walk Type: '),
                DropdownButton<String>(
                  value: _walkType,
                  items: const [
                    DropdownMenuItem(value: 'Bessie', child: Text('Bessie')),
                    DropdownMenuItem(value: 'Marina', child: Text('Marina')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _walkType = val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _startDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Start Date'),
              onTap: () => _pickDate(_startDateCtrl),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'End Date'),
              onTap: () => _pickDate(_endDateCtrl),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startWalk,
              child: const Text('Start Walk'),
            )
          ],
        ),
      ),
    );
  }
}
