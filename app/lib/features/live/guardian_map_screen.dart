import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/ack.dart';
import '../../core/services/firestore_alert_gateway.dart';

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
  String _kind = 'sos';
  DateTime? _updated;
  bool _acked = false;

  Future<void> _acknowledge(AckResponse response) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    var guardianName = 'A guardian';
    if (uid != null) {
      final me = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      guardianName = me.data()?['name'] as String? ?? guardianName;
    }
    await FirestoreAlertGateway().acknowledge(
      widget.trackId,
      Ack(
        id: '',
        guardianName: guardianName,
        response: response,
        at: DateTime.now(),
      ),
    );
    if (mounted) setState(() => _acked = true);

    if (response == AckResponse.callingPolice) {
      final uri = Uri.parse('tel:112'); // region-specific; see Phase 4 notes
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

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
            _kind = data['kind'] as String? ?? _kind;
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
                  top: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Updated ${TimeOfDay.fromDateTime(_updated!).format(context)}',
                      ),
                    ),
                  ),
                ),
              // Guardian response bar — only for an active emergency (not for a
              // benign live-share preview).
              if (_kind == 'sos' && _status == 'active')
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 16,
                  child: _acked
                      ? Card(
                          color: const Color(0xFF2E7D32),
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Response sent — they can see help is coming.',
                                style: TextStyle(color: Colors.white)),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.directions_run),
                                label: const Text("I'm on my way"),
                                onPressed: () =>
                                    _acknowledge(AckResponse.onMyWay),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB71C1C)),
                                icon: const Icon(Icons.local_police),
                                label: const Text('Call police'),
                                onPressed: () =>
                                    _acknowledge(AckResponse.callingPolice),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
