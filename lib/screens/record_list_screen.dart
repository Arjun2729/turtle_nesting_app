// lib/screens/record_list_screen.dart
import 'package:flutter/material.dart';
import '../database/firebase_service.dart';
import 'record_detail_screen.dart';

class RecordListScreen extends StatefulWidget {
  final String walkDocId;
  final String category;
  const RecordListScreen({Key? key, required this.walkDocId, required this.category})
      : super(key: key);

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final all = await FirebaseService().queryRecords();
    // Filter by walkDocId and category
    final filtered = all.where((r) {
      final sameWalk = (r['walkDocId'] == widget.walkDocId);
      final sameCat = (widget.category == r['category']);
      return sameWalk && sameCat;
    }).toList();

    setState(() => records = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category} Records')),
      body: records.isEmpty
          ? const Center(child: Text('No records found.'))
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final rec = records[index];
          return ListTile(
            title: Text('Record #${rec['id']}'),
            subtitle: Text('${rec['date']} ${rec['time']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordDetailScreen(record: rec),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
