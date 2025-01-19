
import 'package:flutter/material.dart';
import '../database/firebase_service.dart';
import 'record_list_screen.dart';
import 'home_screen.dart';

class WalkSummaryScreen extends StatefulWidget {
  final String walkDocId;
  const WalkSummaryScreen({Key? key, required this.walkDocId}) : super(key: key);

  @override
  State<WalkSummaryScreen> createState() => _WalkSummaryScreenState();
}

class _WalkSummaryScreenState extends State<WalkSummaryScreen> {
  Map<String, int> counts = {
    'nest_find': 0,
    'false_crawl': 0,
    'turtle_death': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final all = await FirebaseService().queryRecords();
    final filtered = all.where((r) => r['walkDocId'] == widget.walkDocId);

    final temp = {'nest_find': 0, 'false_crawl': 0, 'turtle_death': 0};
    for (var rec in filtered) {
      final cat = rec['category'];
      if (temp.containsKey(cat)) {
        temp[cat] = temp[cat]! + 1;
      }
    }
    setState(() => counts = temp);
  }

  void _viewRecords(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordListScreen(
          walkDocId: widget.walkDocId,
          category: category,
        ),
      ),
    );
  }

  void _finishWalk() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = counts.values.reduce((a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('Walk Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Total Records: $total'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Nest Find'),
              trailing: Text('${counts['nest_find']}'),
              onTap: () => _viewRecords('nest_find'),
            ),
            ListTile(
              title: const Text('False Crawl'),
              trailing: Text('${counts['false_crawl']}'),
              onTap: () => _viewRecords('false_crawl'),
            ),
            ListTile(
              title: const Text('Turtle Death'),
              trailing: Text('${counts['turtle_death']}'),
              onTap: () => _viewRecords('turtle_death'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _finishWalk,
              child: const Text('Finish Walk'),
            ),
          ],
        ),
      ),
    );
  }
}
