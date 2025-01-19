

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/firebase_service.dart';

Future<Position?> _getLocationOrRequest() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    final result = await Permission.location.request();
    if (!result.isGranted) return null;
  }
  return await Geolocator.getCurrentPosition();
}

/* -------------------------------------------------------
   1) Dead Turtle Form
   ------------------------------------------------------- */
class DeadTurtleFormScreen extends StatefulWidget {
  final String walkDocId;
  final VoidCallback onSaved;
  const DeadTurtleFormScreen({
    Key? key,
    required this.walkDocId,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<DeadTurtleFormScreen> createState() => _DeadTurtleFormScreenState();
}

class _DeadTurtleFormScreenState extends State<DeadTurtleFormScreen> {
  bool _isLoading = false;

  // auto fields
  late String _date;
  late String _time;
  double? _latitude;
  double? _longitude;

  // user fields
  final _idNoCtrl = TextEditingController(); // ID No (This Walk)
  final _cclCtrl = TextEditingController();
  final _ccwCtrl = TextEditingController();
  final _locCtrl = TextEditingController(); // "LOCATION"
  final _sexCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoFill();
  }

  Future<void> _autoFill() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    _date = DateFormat('yyyy-MM-dd').format(now);
    _time = DateFormat('HH:mm:ss').format(now);

    final pos = await _getLocationOrRequest();
    if (pos != null) {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveForm() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available—cannot save.')),
      );
      return;
    }
    final record = {

      'date': _date,
      'time': _time,
      'latitude': _latitude,
      'longitude': _longitude,

      'idNoThisWalk': _idNoCtrl.text,
      'ccl': _cclCtrl.text,
      'ccw': _ccwCtrl.text,
      'location': _locCtrl.text,
      'sex': _sexCtrl.text,
      'remarks': _remarksCtrl.text,


      'category': 'turtle_death',

      // CRITICAL: pass the walkDocId so firebase_service can fetch the walk type
      'walkDocId': widget.walkDocId,
    };

    await FirebaseService().createRecord(record);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Dead Turtle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Text('Date: $_date'),
          Text('Time: $_time'),
          Text('GPS: ${_latitude ?? '??'}, ${_longitude ?? '??'}'),
          const SizedBox(height: 12),

          TextField(
            controller: _idNoCtrl,
            decoration: const InputDecoration(labelText: 'ID No (This Walk)'),
          ),
          TextField(
            controller: _cclCtrl,
            decoration: const InputDecoration(labelText: 'CCL'),
          ),
          TextField(
            controller: _ccwCtrl,
            decoration: const InputDecoration(labelText: 'CCW'),
          ),
          TextField(
            controller: _locCtrl,
            decoration: const InputDecoration(labelText: 'LOCATION'),
          ),
          TextField(
            controller: _sexCtrl,
            decoration: const InputDecoration(labelText: 'SEX'),
          ),
          TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveForm,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------
   2) False Crawl Form
   ------------------------------------------------------- */
class FalseCrawlFormScreen extends StatefulWidget {
  final String walkDocId;
  final VoidCallback onSaved;
  const FalseCrawlFormScreen({
    Key? key,
    required this.walkDocId,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<FalseCrawlFormScreen> createState() => _FalseCrawlFormScreenState();
}

class _FalseCrawlFormScreenState extends State<FalseCrawlFormScreen> {
  bool _isLoading = false;

  // auto
  late String _date;
  late String _time;
  double? _latitude;
  double? _longitude;

  // user
  final _htlCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoFill();
  }

  Future<void> _autoFill() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    _date = DateFormat('yyyy-MM-dd').format(now);
    _time = DateFormat('HH:mm:ss').format(now);

    final pos = await _getLocationOrRequest();
    if (pos != null) {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveForm() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available—cannot save.')),
      );
      return;
    }
    final record = {
      'date': _date,
      'time': _time,
      'latitude': _latitude,
      'longitude': _longitude,

      'htl': _htlCtrl.text,
      'location': _locationCtrl.text,
      'remarks': _remarksCtrl.text,

      'category': 'false_crawl',

      // pass the docId so we can get the actual walk type
      'walkDocId': widget.walkDocId,
    };

    await FirebaseService().createRecord(record);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('False Crawl')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Date: $_date'),
          Text('Time: $_time'),
          Text('GPS: ${_latitude ?? '??'}, ${_longitude ?? '??'}'),
          const SizedBox(height: 12),

          TextField(
            controller: _htlCtrl,
            decoration: const InputDecoration(labelText: 'HTL'),
          ),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveForm,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------
   3) Nest Find Form
   ------------------------------------------------------- */
class NestFindFormScreen extends StatefulWidget {
  final String walkDocId;
  final VoidCallback onSaved;
  const NestFindFormScreen({
    Key? key,
    required this.walkDocId,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<NestFindFormScreen> createState() => _NestFindFormScreenState();
}

class _NestFindFormScreenState extends State<NestFindFormScreen> {
  bool _isLoading = false;

  // auto
  late String _date;
  late String _time;
  double? _latitude;
  double? _longitude;

  // user fields
  final _nestNoCtrl = TextEditingController();
  final _walkTypeCtrl = TextEditingController(); // user can type if needed
  final _nestLocationCtrl = TextEditingController();
  final _distanceHtlCtrl = TextEditingController();
  final _measurementsCtrl = TextEditingController();
  final _noOfEggsCtrl = TextEditingController();
  final _nestFindTimeCtrl = TextEditingController();
  final _relocationTimeCtrl = TextEditingController();
  final _relocatedByCtrl = TextEditingController();
  final _hatcheryLocationCtrl = TextEditingController();
  final _tdCtrl = TextEditingController();
  final _ndCtrl = TextEditingController();
  final _nwCtrl = TextEditingController();
  final _cwCtrl = TextEditingController();
  final _volunteersCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoFill();
  }

  Future<void> _autoFill() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    _date = DateFormat('yyyy-MM-dd').format(now);
    _time = DateFormat('HH:mm:ss').format(now);

    final pos = await _getLocationOrRequest();
    if (pos != null) {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveForm() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available—cannot save')),
      );
      return;
    }
    final record = {
      'date': _date,
      'time': _time,
      'latitude': _latitude,
      'longitude': _longitude,

      'nestNo': _nestNoCtrl.text,
      'walk': _walkTypeCtrl.text, 
      'nestLocation': _nestLocationCtrl.text,
      'distanceHtl': _distanceHtlCtrl.text,
      'measurementsOfTurtle': _measurementsCtrl.text,
      'noOfEggs': _noOfEggsCtrl.text,
      'nestFindTime': _nestFindTimeCtrl.text,
      'relocationTime': _relocationTimeCtrl.text,
      'relocatedBy': _relocatedByCtrl.text,
      'hatcheryLocation': _hatcheryLocationCtrl.text,
      'td': _tdCtrl.text,
      'nd': _ndCtrl.text,
      'nw': _nwCtrl.text,
      'cw': _cwCtrl.text,
      'volunteers': _volunteersCtrl.text,
      'remarks': _remarksCtrl.text,

      'category': 'nest_find',

      // pass walkDocId
      'walkDocId': widget.walkDocId,
    };

    await FirebaseService().createRecord(record);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nest Find')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Date: $_date'),
          Text('Time: $_time'),
          Text('GPS: ${_latitude ?? '??'}, ${_longitude ?? '??'}'),
          const SizedBox(height: 12),

          TextField(
            controller: _nestNoCtrl,
            decoration: const InputDecoration(labelText: 'Nest No'),
          ),
          TextField(
            controller: _walkTypeCtrl,
            decoration: const InputDecoration(labelText: 'Walk (Bessie/Marina)'),
          ),
          TextField(
            controller: _nestLocationCtrl,
            decoration: const InputDecoration(labelText: 'Nest Location'),
          ),
          TextField(
            controller: _distanceHtlCtrl,
            decoration: const InputDecoration(labelText: 'Distance from HTL'),
          ),
          TextField(
            controller: _measurementsCtrl,
            decoration: const InputDecoration(labelText: 'Measurements (if live)'),
          ),
          TextField(
            controller: _noOfEggsCtrl,
            decoration: const InputDecoration(labelText: 'No. of eggs'),
          ),
          TextField(
            controller: _nestFindTimeCtrl,
            decoration: const InputDecoration(labelText: 'Nest Find Time'),
          ),
          TextField(
            controller: _relocationTimeCtrl,
            decoration: const InputDecoration(labelText: 'Relocation Time'),
          ),
          TextField(
            controller: _relocatedByCtrl,
            decoration: const InputDecoration(labelText: 'Relocated By'),
          ),
          TextField(
            controller: _hatcheryLocationCtrl,
            decoration:
            const InputDecoration(labelText: 'Hatchery Location'),
          ),
          TextField(
            controller: _tdCtrl,
            decoration: const InputDecoration(labelText: 'TD'),
          ),
          TextField(
            controller: _ndCtrl,
            decoration: const InputDecoration(labelText: 'ND'),
          ),
          TextField(
            controller: _nwCtrl,
            decoration: const InputDecoration(labelText: 'NW'),
          ),
          TextField(
            controller: _cwCtrl,
            decoration: const InputDecoration(labelText: 'CW'),
          ),
          TextField(
            controller: _volunteersCtrl,
            decoration: const InputDecoration(labelText: 'Volunteers'),
          ),
          TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveForm,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
