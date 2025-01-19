// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/firebase_service.dart';
import 'forms.dart';
import 'record_detail_screen.dart';
import 'walk_summary_screen.dart';

class MapScreen extends StatefulWidget {
  final String walkDocId;
  const MapScreen({Key? key, required this.walkDocId}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(12.9789, 80.2508);
  Set<Marker> _markers = {};
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadMarkers();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        setState(() => _locationGranted = false);
        return;
      }
    }
    _locationGranted = true;
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  Future<void> _loadMarkers() async {
    // Query all records for this walk
    final records = await FirebaseService().queryRecords();
    final filtered = records.where((r) => r['walkDocId'] == widget.walkDocId);

    final newMarkers = <Marker>{};
    for (var rec in filtered) {
      final lat = (rec['latitude'] is num) ? (rec['latitude'] as num).toDouble() : 0.0;
      final lng = (rec['longitude'] is num) ? (rec['longitude'] as num).toDouble() : 0.0;
      final markerId = rec['id'].toString();
      newMarkers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: rec['category']?.toString() ?? '',
            snippet: 'Tap for details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordDetailScreen(record: rec),
                ),
              );
            },
          ),
        ),
      );
    }
    setState(() => _markers = newMarkers);
  }

  void _chooseCategory() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: const Text('Nest Find'),
              onTap: () => _navigateToForm('nest_find'),
            ),
            ListTile(
              title: const Text('False Crawl'),
              onTap: () => _navigateToForm('false_crawl'),
            ),
            ListTile(
              title: const Text('Turtle Death'),
              onTap: () => _navigateToForm('turtle_death'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToForm(String category) async {
    Navigator.pop(context);
    Widget formScreen;
    switch (category) {
      case 'nest_find':
        formScreen = NestFindFormScreen(
          walkDocId: widget.walkDocId,
          onSaved: _loadMarkers,
        );
        break;
      case 'false_crawl':
        formScreen = FalseCrawlFormScreen(
          walkDocId: widget.walkDocId,
          onSaved: _loadMarkers,
        );
        break;
      default:
        formScreen = DeadTurtleFormScreen(
          walkDocId: widget.walkDocId,
          onSaved: _loadMarkers,
        );
        break;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => formScreen));
  }

  void _endWalk() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalkSummaryScreen(walkDocId: widget.walkDocId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turtle Nesting Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _endWalk,
          )
        ],
      ),
      body: GoogleMap(
        onMapCreated: (c) => _mapController = c,
        initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
        markers: _markers,
        myLocationEnabled: _locationGranted,
        myLocationButtonEnabled: _locationGranted,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _chooseCategory,
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
