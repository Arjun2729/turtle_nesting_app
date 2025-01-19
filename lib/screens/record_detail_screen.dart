// lib/screens/record_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const RecordDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double lat = 0.0;
    double lng = 0.0;
    if (record['latitude'] is num) {
      lat = (record['latitude'] as num).toDouble();
    }
    if (record['longitude'] is num) {
      lng = (record['longitude'] as num).toDouble();
    }
    final pos = LatLng(lat, lng);

    // gather all keys
    final sortedKeys = record.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Record Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Fields:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // display each key/value
            ...sortedKeys.map((k) {
              final val = record[k];
              return Text('$k: $val');
            }).toList(),

            const SizedBox(height: 16),
            if (lat != 0.0 || lng != 0.0) ...[
              const Text(
                'Location Map:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: pos, zoom: 14),
                  markers: {
                    Marker(
                      markerId: const MarkerId('rec'),
                      position: pos,
                    ),
                  },
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
