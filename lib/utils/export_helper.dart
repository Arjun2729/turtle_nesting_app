// lib/utils/export_helper.dart
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

/// Converts a list of record maps into a CSV string that includes all fields.
String convertRecordsToCsv(List<Map<String, dynamic>> records) {
  if (records.isEmpty) return '';

  // Gather all unique keys from the records.
  final allKeys = <String>{};
  for (var record in records) {
    allKeys.addAll(record.keys);
  }
  final sortedKeys = allKeys.toList()..sort();

  // Build rows: header row then one row per record.
  final rows = <List<dynamic>>[];
  rows.add(sortedKeys);
  for (var record in records) {
    final row = sortedKeys.map((k) => record[k]?.toString() ?? '').toList();
    rows.add(row);
  }

  return const ListToCsvConverter().convert(rows);
}

/// Converts a list of record maps into an Excel file (as Uint8List) that includes all fields.
Uint8List convertRecordsToExcel(List<Map<String, dynamic>> records) {
  final excel = Excel.createExcel();
  final sheet = excel['Records'];

  if (records.isNotEmpty) {
    final allKeys = <String>{};
    for (var record in records) {
      allKeys.addAll(record.keys);
    }
    final sortedKeys = allKeys.toList()..sort();
    sheet.appendRow(sortedKeys);
    for (var record in records) {
      final row = sortedKeys.map((k) => record[k]?.toString() ?? '').toList();
      sheet.appendRow(row);
    }
  }

  return Uint8List.fromList(excel.encode()!);
}
