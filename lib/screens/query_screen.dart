
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../database/firebase_service.dart';
import '../utils/export_helper.dart';

class QueryScreen extends StatefulWidget {
  const QueryScreen({Key? key}) : super(key: key);

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _records = [];
  Set<Marker> _markers = {};
  LatLng _initialPos = const LatLng(12.9789, 80.2508);


  final TextEditingController _startDateCtrl = TextEditingController();
  final TextEditingController _endDateCtrl = TextEditingController();


  List<String> _allKeys = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    _startDateCtrl.text = DateFormat('yyyy-MM-dd').format(now);
    _endDateCtrl.text = DateFormat('yyyy-MM-dd').format(tomorrow);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Query & Export Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Export Excel',
            onPressed: _exportExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilters(),
          ElevatedButton(
            onPressed: _runQuery,
            child: const Text('Run Query'),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(),
            ),
          ),
          SizedBox(
            height: 250,
            child: GoogleMap(
              onMapCreated: (controller) {},
              initialCameraPosition:
              CameraPosition(target: _initialPos, zoom: 14),
              markers: _markers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _startDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Start Date'),
              onTap: () => _pickDate(_startDateCtrl),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _endDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'End Date'),
              onTap: () => _pickDate(_endDateCtrl),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _runQuery() async {
    setState(() => _isLoading = true);

    final String startDate = _startDateCtrl.text;
    final String endDate = _endDateCtrl.text;


    final results = await FirebaseService().queryRecords(
      startDate: startDate,
      endDate: endDate,
      walkType: null,
      category: null,
    );

    _records = results;
    _markers.clear();

    if (_records.isNotEmpty) {

      final first = _records.first;
      double lat = 12.9789, lng = 80.2508;
      if (first['latitude'] is num) {
        lat = (first['latitude'] as num).toDouble();
      }
      if (first['longitude'] is num) {
        lng = (first['longitude'] as num).toDouble();
      }
      _initialPos = LatLng(lat, lng);

      for (var rec in _records) {
        double rLat = 0.0, rLng = 0.0;
        if (rec['latitude'] is num) rLat = (rec['latitude'] as num).toDouble();
        if (rec['longitude'] is num) rLng = (rec['longitude'] as num).toDouble();
        final markerIdStr = rec['id']?.toString() ?? 'no_id';
        final catStr = rec['category']?.toString() ?? '';
        _markers.add(
          Marker(
            markerId: MarkerId(markerIdStr),
            position: LatLng(rLat, rLng),
            infoWindow: InfoWindow(title: catStr),
          ),
        );
      }
    }


    final allKeys = <String>{};
    for (var rec in _records) {
      allKeys.addAll(rec.keys);
    }
    _allKeys = allKeys.toList()..sort();

    setState(() => _isLoading = false);
  }

  Widget _buildDataTable() {
    if (_records.isEmpty) {
      return const Text('No records to display.');
    }
    final columns = _allKeys
        .map((k) => DataColumn(
      label: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
    ))
        .toList();
    final rows = _records.map((record) {
      return DataRow(
        cells: _allKeys
            .map((k) => DataCell(Text(record[k]?.toString() ?? '')))
            .toList(),
      );
    }).toList();

    return DataTable(columns: columns, rows: rows);
  }

  Future<void> _exportCsv() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export.')));
      return;
    }
    try {
      final csvData = convertRecordsToCsv(_records);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/my_export.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(path)], text: 'My exported CSV');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    }
  }

  Future<void> _exportExcel() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export.')));
      return;
    }
    try {
      final excelBytes = convertRecordsToExcel(_records);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/my_export.xlsx';
      final file = File(path);
      await file.writeAsBytes(excelBytes);
      await Share.shareXFiles([XFile(path)], text: 'My exported Excel');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    }
  }
}
