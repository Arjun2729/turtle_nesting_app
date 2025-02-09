// lib/database/google_sheets_service.dart
import 'package:gsheets/gsheets.dart';
import 'package:flutter/foundation.dart'; // for listEquals
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSheetsService {
  static final GoogleSheetsService _instance = GoogleSheetsService._internal();
  factory GoogleSheetsService() => _instance;
  GoogleSheetsService._internal();

  // REPLACE with your actual spreadsheet ID.
  static const _spreadsheetId = '1yMRReLqDcByJddNfQzCsNx0zj1PuH7Lu19sTp-33Pxk';

  late final GSheets _gsheets;
  late final Spreadsheet _spreadsheet;
  late Worksheet _deadTurtleSheet;
  late Worksheet _falseCrawlSheet;
  late Worksheet _nestFindSheet;
  late Worksheet _summarySheet;

  bool _initialized = false;
  Future<void>? _initFuture; // Cache initialization future

  // --- Worksheet Headers ---
  static const List<String> _deadTurtleHeaders = [
    'S.No',
    'UserName',
    'Date',
    'Time',
    'GPS',
    'Walk',
    'CCL',
    'CCW',
    'LOCATION',
    'SEX',
    'Remarks',
    'Volunteers/Walk by:'
  ];

  static const List<String> _falseCrawlHeaders = [
    'S.No',
    'UserName',
    'Date',
    'Time',
    'GPS',
    'HTL',
    'Location',
    'Remarks',
    'Volunteers/Walk by:'
  ];

  static const List<String> _nestFindHeaders = [
    'S.No',
    'UserName',
    'Date:',
    'Walk (Bessie/Marina):',
    'Nest location:',
    'Distance from high tide line:',
    'ccl live nesting',
    'ccw live nesting',
    'No.of eggs:',
    'Broken:',
    'Spoiled:',
    'Deformed:',
    'Nest find time:',
    'Relocation time:',
    'Relocated by:',
    'Place/location in hatchery (row/no):',
    'TD:',
    'ND:',
    'NW1:',
    'NW2:',
    'CW1:',
    'CW2:',
    'Volunteers/Walk by:',
    'Remarks:',
    'GPS:'
  ];

  static const List<String> _summaryHeaders = [
    'Date',
    'Stretch',
    'No. of nests',
    'No. of eggs',
    'No. of dead turtles',
    'Volunteers'
  ];

  /// Ensures the worksheet has a header row that exactly matches [headers].
  Future<void> _ensureHeader(Worksheet sheet, List<String> headers) async {
    final firstRow = await sheet.values.row(1);
    // If header row is missing or does not match exactly, insert the headers.
    if (firstRow == null || firstRow.isEmpty || !listEquals(firstRow, headers)) {
      // Clear the sheet and insert header.
      await sheet.clear();
      await sheet.values.insertRow(1, headers);
    }
  }

  /// Helper: Attempts to get or create a worksheet with the given [name].
  Future<Worksheet> _getOrCreateWorksheet(String name) async {
    Worksheet? sheet = _spreadsheet.worksheetByTitle(name);
    if (sheet == null) {
      for (var ws in _spreadsheet.sheets) {
        if (ws.title.toLowerCase() == name.toLowerCase()) {
          sheet = ws;
          break;
        }
      }
    }
    if (sheet == null) {
      try {
        sheet = await _spreadsheet.addWorksheet(name);
      } catch (e) {
        for (var ws in _spreadsheet.sheets) {
          if (ws.title.toLowerCase() == name.toLowerCase()) {
            sheet = ws;
            break;
          }
        }
      }
    }
    if (sheet == null) {
      throw Exception("Worksheet '$name' could not be created or retrieved.");
    }
    return sheet;
  }

  /// Initializes the GSheets service and ensures each worksheet exists with its header.
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initFuture != null) return await _initFuture;

    _initFuture = () async {
      final credentials = await rootBundle.loadString('assets/service_account.json');
      _gsheets = GSheets(credentials);
      _spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);

      _deadTurtleSheet = await _getOrCreateWorksheet('Dead Turtle');
      _falseCrawlSheet = await _getOrCreateWorksheet('False Crawl');
      _nestFindSheet = await _getOrCreateWorksheet('Nest Find');
      _summarySheet = await _getOrCreateWorksheet('Records');

      await _ensureHeader(_deadTurtleSheet, _deadTurtleHeaders);
      await _ensureHeader(_falseCrawlSheet, _falseCrawlHeaders);
      await _ensureHeader(_nestFindSheet, _nestFindHeaders);
      await _ensureHeader(_summarySheet, _summaryHeaders);

      _initialized = true;
    }();
    await _initFuture;
  }

  /// Computes the serial number for the new record.
  /// It counts the non-empty rows (ignoring the header).
  Future<int> _getNewRowNumber(Worksheet sheet) async {
    final allRows = await sheet.values.allRows();
    // allRows includes header; count data rows only:
    final dataRows = allRows.skip(1).where((row) => row.any((cell) => cell.trim().isNotEmpty));
    return dataRows.length + 1;
  }

  /// Determines the Walk based on the GPS coordinate.
  String determineWalk(String? gps, String defaultWalk) {
    if (gps != null && gps.isNotEmpty) {
      final parts = gps.split(',');
      if (parts.isNotEmpty) {
        final lat = double.tryParse(parts[0].trim());
        if (lat != null) {
          return (lat > 13.013482) ? 'Marina' : 'Bessie';
        }
      }
    }
    return defaultWalk;
  }

  /// Converts a raw date string (possibly an Excel serial date) into "dd/MM/yy" format.
  String _formatDate(String raw) {
    double? serial = double.tryParse(raw);
    if (serial != null) {
      DateTime dt = DateTime(1899, 12, 30).add(Duration(days: serial.toInt()));
      return DateFormat('dd/MM/yy').format(dt);
    }
    return raw;
  }

  /// Logs a record to the appropriate worksheet based on [eventType].
  Future<void> logRecord({
    required String eventType,
    required String date,
    required String time,
    String? gps,
    required Map<String, String> recordData,
  }) async {
    await initialize();

    Worksheet sheet;
    List<String> headers;
    Map<String, String> dataMap = {};
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Unknown';

    switch (eventType) {
      case 'Dead Turtle':
        sheet = _deadTurtleSheet;
        headers = _deadTurtleHeaders;
        recordData['Walk'] = determineWalk(gps, '');
        dataMap = {
          'S.No': (await _getNewRowNumber(sheet)).toString(),
          'UserName': userName,
          'Date': date,
          'Time': time,
          'GPS': gps ?? '',
        };
        dataMap.addAll(recordData);
        break;
      case 'False Crawl':
        sheet = _falseCrawlSheet;
        headers = _falseCrawlHeaders;
        dataMap = {
          'S.No': (await _getNewRowNumber(sheet)).toString(),
          'UserName': userName,
          'Date': date,
          'Time': time,
          'GPS': gps ?? '',
        };
        dataMap.addAll(recordData);
        break;
      case 'Nest Find':
        sheet = _nestFindSheet;
        headers = _nestFindHeaders;
        dataMap = {
          'S.No': (await _getNewRowNumber(sheet)).toString(),
          'UserName': userName,
          'Date:': date,
          'Walk (Bessie/Marina):': recordData['Walk (Bessie/Marina):'] ?? determineWalk(gps, ''),
        };
        dataMap.addAll(recordData);
        break;
      default:
        throw Exception("Unknown event type: $eventType");
    }

    List<String> rowData = headers.map((header) => dataMap[header] ?? '').toList();
    await sheet.values.appendRow(rowData);
  }

  /// Converts a list of row values into a map using the header list.
  Map<String, String> _listToMap(List<String> headers, List<String> row) {
    Map<String, String> map = {};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i]] = i < row.length ? row[i] : '';
    }
    return map;
  }

  /// Updates the summary (Records) sheet by aggregating data from the three category sheets.
  Future<void> updateSummarySheet() async {
    try {
      Map<String, Map<String, dynamic>> summary = {};

      // Process Dead Turtle records.
      List<List<String>> dtRows = await _deadTurtleSheet.values.allRows();
      if (dtRows.length > 1) {
        List<String> dtHeaders = dtRows.first;
        for (var row in dtRows.sublist(1)) {
          var rowMap = _listToMap(dtHeaders, row);
          String date = _formatDate(rowMap['Date'] ?? '');
          String gps = rowMap['GPS'] ?? '';
          String stretch = determineWalk(gps, '');
          String key = '$date|$stretch';
          summary.putIfAbsent(key, () => {
            'Date': date,
            'Stretch': stretch,
            'No. of nests': 0,
            'No. of eggs': 0,
            'No. of dead turtles': 0,
            'Volunteers': <String>{},
          });
          summary[key]!['No. of dead turtles'] += 1;
          String vols = rowMap['Volunteers/Walk by:'] ?? '';
          if (vols.isNotEmpty) {
            (summary[key]!['Volunteers'] as Set<String>).addAll(
                vols.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)
            );
          }
        }
      }

      // Process False Crawl records.
      List<List<String>> fcRows = await _falseCrawlSheet.values.allRows();
      if (fcRows.length > 1) {
        List<String> fcHeaders = fcRows.first;
        for (var row in fcRows.sublist(1)) {
          var rowMap = _listToMap(fcHeaders, row);
          String date = _formatDate(rowMap['Date'] ?? '');
          String gps = rowMap['GPS'] ?? '';
          String stretch = determineWalk(gps, '');
          String key = '$date|$stretch';
          summary.putIfAbsent(key, () => {
            'Date': date,
            'Stretch': stretch,
            'No. of nests': 0,
            'No. of eggs': 0,
            'No. of dead turtles': 0,
            'Volunteers': <String>{},
          });
          String vols = rowMap['Volunteers/Walk by:'] ?? '';
          if (vols.isNotEmpty) {
            (summary[key]!['Volunteers'] as Set<String>).addAll(
                vols.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)
            );
          }
        }
      }

      // Process Nest Find records.
      List<List<String>> nfRows = await _nestFindSheet.values.allRows();
      if (nfRows.length > 1) {
        List<String> nfHeaders = nfRows.first;
        for (var row in nfRows.sublist(1)) {
          var rowMap = _listToMap(nfHeaders, row);
          String date = _formatDate(rowMap['Date:'] ?? '');
          String stretch = rowMap['Walk (Bessie/Marina):'] ?? '';
          String key = '$date|$stretch';
          summary.putIfAbsent(key, () => {
            'Date': date,
            'Stretch': stretch,
            'No. of nests': 0,
            'No. of eggs': 0,
            'No. of dead turtles': 0,
            'Volunteers': <String>{},
          });
          summary[key]!['No. of nests'] += 1;
          int eggs = int.tryParse(rowMap['No.of eggs:'] ?? '') ?? 0;
          summary[key]!['No. of eggs'] += eggs;
          String volsStr = rowMap['Volunteers/Walk by:'] ?? '';
          List<String> vols = volsStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          (summary[key]!['Volunteers'] as Set<String>).addAll(vols);
        }
      }

      List<List<String>> summaryRows = [];
      summaryRows.add(_summaryHeaders);
      for (var key in summary.keys) {
        var data = summary[key]!;
        String volunteers = (data['Volunteers'] as Set<String>).join(', ');
        List<String> row = [
          data['Date'] ?? '',
          data['Stretch'] ?? '',
          (data['No. of nests']).toString(),
          (data['No. of eggs']).toString(),
          (data['No. of dead turtles']).toString(),
          volunteers,
        ];
        summaryRows.add(row);
      }

      await _summarySheet.clear();
      await _summarySheet.values.insertRows(1, summaryRows);
    } catch (e) {
      print("Error updating summary sheet: $e");
    }
  }
}
