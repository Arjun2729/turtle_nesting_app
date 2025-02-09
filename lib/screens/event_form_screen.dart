//lib/screens/event_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/google_sheets_service.dart';

class EventFormScreen extends StatefulWidget {
  final String eventType;
  const EventFormScreen({Key? key, required this.eventType}) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  bool _isLoading = false;
  late String _date;
  late String _time;
  String? _gps;
  String _computedWalk = '';
  String _userName = '';

  // --- Controllers for Dead Turtle (ID removed) ---
  final TextEditingController _deadCclCtrl = TextEditingController();
  final TextEditingController _deadCcwCtrl = TextEditingController();
  final TextEditingController _deadLocationCtrl = TextEditingController();
  final TextEditingController _deadSexCtrl = TextEditingController();
  final TextEditingController _deadRemarksCtrl = TextEditingController();

  // --- Controllers for False Crawl ---
  final TextEditingController _falseHtlCtrl = TextEditingController();
  final TextEditingController _falseLocationCtrl = TextEditingController();
  final TextEditingController _falseRemarksCtrl = TextEditingController();

  // --- Controllers for Nest Find ---
  // S.No is auto-generated so no input field.
  final TextEditingController _nestLocationCtrl = TextEditingController();
  final TextEditingController _nestDistanceCtrl = TextEditingController();
  // Two separate controllers for live nesting measurements.
  final TextEditingController _nestCclLiveCtrl = TextEditingController();
  final TextEditingController _nestCcwLiveCtrl = TextEditingController();
  final TextEditingController _nestNoOfEggsCtrl = TextEditingController();
  final TextEditingController _nestBrokenCtrl = TextEditingController();
  final TextEditingController _nestSpoiledCtrl = TextEditingController();
  final TextEditingController _nestDeformedCtrl = TextEditingController();
  final TextEditingController _nestFindTimeCtrl = TextEditingController();
  final TextEditingController _nestRelocationTimeCtrl = TextEditingController();
  final TextEditingController _nestRelocatedByCtrl = TextEditingController();
  final TextEditingController _nestHatcheryLocationCtrl = TextEditingController();
  // For nest dimensions.
  final TextEditingController _nestTdCtrl = TextEditingController();
  final TextEditingController _nestNdCtrl = TextEditingController();
  final TextEditingController _nestNw1Ctrl = TextEditingController();
  final TextEditingController _nestNw2Ctrl = TextEditingController();
  final TextEditingController _nestCw1Ctrl = TextEditingController();
  final TextEditingController _nestCw2Ctrl = TextEditingController();
  final TextEditingController _nestRemarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadUserName();
  }

  Future<void> _initializeForm() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    // Date format: dd/MM/yy
    _date = DateFormat('dd/MM/yy').format(now);
    _time = DateFormat('HH:mm:ss').format(now);
    final position = await _getLocation();
    if (position != null) {
      _gps = "${position.latitude}, ${position.longitude}";
      _computedWalk = GoogleSheetsService().determineWalk(_gps, '');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Unknown';
    });
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _saveRecord() async {
    if (_gps == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('GPS not available, cannot save.')));
      return;
    }

    // Retrieve volunteer names from SharedPreferences (set in VolunteersScreen)
    final prefs = await SharedPreferences.getInstance();
    String volunteers = prefs.getString('volunteers') ?? '';

    Map<String, String> recordData = {};
    // Add volunteer names using the key matching the header.
    recordData['Volunteers/Walk by:'] = volunteers;

    if (widget.eventType == 'Dead Turtle') {
      recordData.addAll({
        'CCL': _deadCclCtrl.text.trim(),
        'CCW': _deadCcwCtrl.text.trim(),
        'LOCATION': _deadLocationCtrl.text.trim(),
        'SEX': _deadSexCtrl.text.trim(),
        'Remarks': _deadRemarksCtrl.text.trim(),
      });
    } else if (widget.eventType == 'False Crawl') {
      recordData.addAll({
        'HTL': _falseHtlCtrl.text.trim(),
        'Location': _falseLocationCtrl.text.trim(),
        'Remarks': _falseRemarksCtrl.text.trim(),
      });
    } else if (widget.eventType == 'Nest Find') {
      recordData.addAll({
        'Nest location:': _nestLocationCtrl.text.trim(),
        'Distance from high tide line:': _nestDistanceCtrl.text.trim(),
        'ccl live nesting': _nestCclLiveCtrl.text.trim(),
        'ccw live nesting': _nestCcwLiveCtrl.text.trim(),
        'No.of eggs:': _nestNoOfEggsCtrl.text.trim(),
        'Broken:': _nestBrokenCtrl.text.trim(),
        'Spoiled:': _nestSpoiledCtrl.text.trim(),
        'Deformed:': _nestDeformedCtrl.text.trim(),
        'Nest find time:': _nestFindTimeCtrl.text.trim(),
        'Relocation time:': _nestRelocationTimeCtrl.text.trim(),
        'Relocated by:': _nestRelocatedByCtrl.text.trim(),
        'Place/location in hatchery (row/no):': _nestHatcheryLocationCtrl.text.trim(),
        // Combine nest dimensions.
        'Nest dimensions:': '${_nestTdCtrl.text.trim()}, ${_nestNdCtrl.text.trim()}, ${_nestNw1Ctrl.text.trim()}, ${_nestNw2Ctrl.text.trim()}, ${_nestCw1Ctrl.text.trim()}, ${_nestCw2Ctrl.text.trim()}',
        'TD:': _nestTdCtrl.text.trim(),
        'ND:': _nestNdCtrl.text.trim(),
        'NW1:': _nestNw1Ctrl.text.trim(),
        'NW2:': _nestNw2Ctrl.text.trim(),
        'CW1:': _nestCw1Ctrl.text.trim(),
        'CW2:': _nestCw2Ctrl.text.trim(),
        'Remarks:': _nestRemarksCtrl.text.trim(),
        'GPS:': _gps ?? '',
      });
    }

    await GoogleSheetsService().logRecord(
      eventType: widget.eventType,
      date: _date,
      time: _time,
      gps: _gps,
      recordData: recordData,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Record saved successfully.')));
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Auto-recorded information section at the top.
  Widget _buildAutoRecordedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date: $_date', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Time: $_time', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('GPS: ${_gps ?? 'Not available'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Walk: $_computedWalk', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('UserName: $_userName', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
      ],
    );
  }

  /// User input section for Dead Turtle.
  Widget _buildDeadTurtleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _deadCclCtrl,
          decoration: const InputDecoration(labelText: 'CCL'),
        ),
        TextField(
          controller: _deadCcwCtrl,
          decoration: const InputDecoration(labelText: 'CCW'),
        ),
        TextField(
          controller: _deadLocationCtrl,
          decoration: const InputDecoration(labelText: 'LOCATION'),
        ),
        TextField(
          controller: _deadSexCtrl,
          decoration: const InputDecoration(labelText: 'SEX'),
        ),
        TextField(
          controller: _deadRemarksCtrl,
          decoration: const InputDecoration(labelText: 'Remarks'),
          maxLines: 3,
        ),
      ],
    );
  }

  /// User input section for False Crawl.
  Widget _buildFalseCrawlForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _falseHtlCtrl,
          decoration: const InputDecoration(labelText: 'HTL'),
        ),
        TextField(
          controller: _falseLocationCtrl,
          decoration: const InputDecoration(labelText: 'Location'),
        ),
        TextField(
          controller: _falseRemarksCtrl,
          decoration: const InputDecoration(labelText: 'Remarks'),
          maxLines: 3,
        ),
      ],
    );
  }

  /// User input section for Nest Find.
  Widget _buildNestFindForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nestLocationCtrl,
          decoration: const InputDecoration(labelText: 'Nest location:'),
        ),
        TextField(
          controller: _nestDistanceCtrl,
          decoration: const InputDecoration(labelText: 'Distance from high tide line:'),
        ),
        TextField(
          controller: _nestCclLiveCtrl,
          decoration: const InputDecoration(labelText: 'ccl live nesting'),
        ),
        TextField(
          controller: _nestCcwLiveCtrl,
          decoration: const InputDecoration(labelText: 'ccw live nesting'),
        ),
        TextField(
          controller: _nestNoOfEggsCtrl,
          decoration: const InputDecoration(labelText: 'No.of eggs:'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _nestBrokenCtrl,
          decoration: const InputDecoration(labelText: 'Broken:'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _nestSpoiledCtrl,
          decoration: const InputDecoration(labelText: 'Spoiled:'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _nestDeformedCtrl,
          decoration: const InputDecoration(labelText: 'Deformed:'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _nestFindTimeCtrl,
          decoration: const InputDecoration(labelText: 'Nest find time:'),
        ),
        TextField(
          controller: _nestRelocationTimeCtrl,
          decoration: const InputDecoration(labelText: 'Relocation time:'),
        ),
        TextField(
          controller: _nestRelocatedByCtrl,
          decoration: const InputDecoration(labelText: 'Relocated by:'),
        ),
        TextField(
          controller: _nestHatcheryLocationCtrl,
          decoration: const InputDecoration(labelText: 'Place/location in hatchery (row/no):'),
        ),
        const SizedBox(height: 8),
        const Text('Nest dimensions:'),
        TextField(
          controller: _nestTdCtrl,
          decoration: const InputDecoration(labelText: 'TD:'),
        ),
        TextField(
          controller: _nestNdCtrl,
          decoration: const InputDecoration(labelText: 'ND:'),
        ),
        TextField(
          controller: _nestNw1Ctrl,
          decoration: const InputDecoration(labelText: 'NW1:'),
        ),
        TextField(
          controller: _nestNw2Ctrl,
          decoration: const InputDecoration(labelText: 'NW2:'),
        ),
        TextField(
          controller: _nestCw1Ctrl,
          decoration: const InputDecoration(labelText: 'CW1:'),
        ),
        TextField(
          controller: _nestCw2Ctrl,
          decoration: const InputDecoration(labelText: 'CW2:'),
        ),
        TextField(
          controller: _nestRemarksCtrl,
          decoration: const InputDecoration(labelText: 'Remarks:'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildUserInputSection() {
    switch (widget.eventType) {
      case 'Dead Turtle':
        return _buildDeadTurtleForm();
      case 'False Crawl':
        return _buildFalseCrawlForm();
      case 'Nest Find':
        return _buildNestFindForm();
      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    // Dispose controllers for Dead Turtle.
    _deadCclCtrl.dispose();
    _deadCcwCtrl.dispose();
    _deadLocationCtrl.dispose();
    _deadSexCtrl.dispose();
    _deadRemarksCtrl.dispose();
    // Dispose controllers for False Crawl.
    _falseHtlCtrl.dispose();
    _falseLocationCtrl.dispose();
    _falseRemarksCtrl.dispose();
    // Dispose controllers for Nest Find.
    _nestLocationCtrl.dispose();
    _nestDistanceCtrl.dispose();
    _nestCclLiveCtrl.dispose();
    _nestCcwLiveCtrl.dispose();
    _nestNoOfEggsCtrl.dispose();
    _nestBrokenCtrl.dispose();
    _nestSpoiledCtrl.dispose();
    _nestDeformedCtrl.dispose();
    _nestFindTimeCtrl.dispose();
    _nestRelocationTimeCtrl.dispose();
    _nestRelocatedByCtrl.dispose();
    _nestHatcheryLocationCtrl.dispose();
    _nestTdCtrl.dispose();
    _nestNdCtrl.dispose();
    _nestNw1Ctrl.dispose();
    _nestNw2Ctrl.dispose();
    _nestCw1Ctrl.dispose();
    _nestCw2Ctrl.dispose();
    _nestRemarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record ${widget.eventType}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAutoRecordedSection(),
            _buildUserInputSection(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRecord,
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}

