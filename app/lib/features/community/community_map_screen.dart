import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/models/safety_report.dart';
import '../../core/repositories/safety_report_repository.dart';
import '../../core/services/location_service.dart';
import 'report_sheet.dart';

/// Community safety map: shows pseudonymous area reports as coloured zones and
/// lets the user contribute one for wherever the map is centred.
class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key, required this.repo});

  final SafetyReportRepository repo;

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  final LocationService _location = LocationService();
  GoogleMapController? _map;
  LatLng _center = const LatLng(20.5937, 78.9629); // India centroid fallback
  bool _loading = true;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (await _location.ensurePermission()) {
      final pos = await _location.currentFix();
      if (pos != null) _center = LatLng(pos.latitude, pos.longitude);
    }
    await _reload();
    if (mounted) {
      setState(() => _loading = false);
      _map?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    }
  }

  Future<void> _reload() async {
    final reports = await widget.repo.nearby(
      lat: _center.latitude,
      lng: _center.longitude,
      radiusKm: 3,
    );
    final circles = <Circle>{};
    final markers = <Marker>{};
    for (final r in reports) {
      final color = r.category.isPositive ? Colors.green : Colors.redAccent;
      final pos = LatLng(r.lat, r.lng);
      circles.add(Circle(
        circleId: CircleId(r.id),
        center: pos,
        radius: 60,
        fillColor: color.withOpacity(0.25),
        strokeColor: color.withOpacity(0.6),
        strokeWidth: 1,
      ));
      markers.add(Marker(
        markerId: MarkerId(r.id),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(r.category.isPositive
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: r.category.label,
          snippet: r.note,
        ),
      ));
    }
    if (mounted) setState(() {
      _circles = circles;
      _markers = markers;
    });
  }

  Future<void> _report() async {
    final result = await showModalBottomSheet<ReportChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ReportSheet(),
    );
    if (result == null) return;
    await widget.repo.add(
      lat: _center.latitude,
      lng: _center.longitude,
      category: result.category,
      note: result.note,
    );
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your report helps others.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community safety'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload this area',
            onPressed: _reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _report,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Report area'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _center, zoom: 15),
                  onMapCreated: (c) => _map = c,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  circles: _circles,
                  markers: _markers,
                  onCameraMove: (pos) => _center = pos.target,
                ),
                // Centre crosshair so the user knows where a report lands.
                const IgnorePointer(
                  child: Center(
                    child: Icon(Icons.add, size: 36, color: Colors.black54),
                  ),
                ),
                const Positioned(
                  left: 12,
                  bottom: 12,
                  child: _Legend(),
                ),
              ],
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.circle, color: Colors.green, size: 12),
            SizedBox(width: 4),
            Text('Safe'),
            SizedBox(width: 12),
            Icon(Icons.circle, color: Colors.redAccent, size: 12),
            SizedBox(width: 4),
            Text('Caution'),
          ],
        ),
      ),
    );
  }
}
