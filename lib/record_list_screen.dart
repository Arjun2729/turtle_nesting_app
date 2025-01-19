import 'package:flutter/material.dart';
import '../database/firebase_service.dart';
import 'record_detail_screen.dart';

class RecordListScreen extends StatefulWidget {
  final String walkDocId;
  final String category;
  const RecordListScreen({
    Key? key,
    required this.walkDocId,
    required this.category,
  }) : super(key: key);

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
    final all = await FirebaseService().queryRecords(
      category: widget.category == 'all' ? null : widget.category,
    );
    final filtered = all.where((r) => r['walkId'] == widget.walkDocId).toList();
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
          final r = records[index];
          return ListTile(
            title: Text('Record #${r['id']}'),
            subtitle: Text(r['dateTime'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecordDetailScreen(record: r)),
              );
            },
          );
        },
      ),
    );
  }
}
