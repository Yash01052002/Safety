import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// In-app live map a guardian uses to watch a shared session. Reads the same
/// `publicTracks/{id}` projection the web page uses, so a guardian who has the
/// app gets a native map instead of the browser page.
class GuardianMapScreen extends StatefulWidget {
  const GuardianMapScreen({super.key, required this.trackId});

  /// The event/session id from the SOS push or a shared link.
  final String trackId;

  @override
  State<GuardianMapScreen> createState() => _GuardianMapScreenState();
}

class _GuardianMapScreenState extends State<GuardianMapScreen> {
  GoogleMapController? _map;
  LatLng? _pos;
  String _name = 'Someone';
  String _status = 'active';
  DateTime? _updated;

  @override
  Widget build(BuildContext context) {
    final active = _status == 'active';
    return Scaffold(
      appBar: AppBar(
        title: Text(active ? '$_name — live' : '$_name'),
        backgroundColor: active ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('publicTracks')
            .doc(widget.trackId)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data();
          if (data != null) {
            _name = data['userName'] as String? ?? _name;
            _status = data['status'] as String? ?? _status;
            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              _pos = LatLng(lat, lng);
              _map?.animateCamera(CameraUpdate.newLatLng(_pos!));
            }
            final ts = data['updatedAt'];
            if (ts is Timestamp) _updated = ts.toDate();
          }

          if (_pos == null) {
            return const Center(child: Text('Waiting for location…'));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _pos!, zoom: 16),
                onMapCreated: (c) => _map = c,
                myLocationEnabled: true,
                markers: {
                  Marker(
                    markerId: const MarkerId('subject'),
                    position: _pos!,
                    infoWindow: InfoWindow(title: _name),
                  ),
                },
              ),
              if (_updated != null)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Updated ${TimeOfDay.fromDateTime(_updated!).format(context)}',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
