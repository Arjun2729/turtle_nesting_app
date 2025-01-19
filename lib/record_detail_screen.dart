// lib/record_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const RecordDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double lat = record['latitude'];
    final double lng = record['longitude'];
    final LatLng pos = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(title: Text('Record #${record['id']} Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${record['category']}'),
            Text('DateTime: ${record['dateTime']}'),
            Text('Latitude: $lat'),
            Text('Longitude: $lng'),
            Text('Remarks: ${record['remarks'] ?? ''}'),
            // Display additional fields if necessary:
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: pos, zoom: 15),
                markers: {
                  Marker(markerId: const MarkerId('detail'), position: pos),
                },
                zoomControlsEnabled: false,
                myLocationEnabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
