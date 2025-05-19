// lib/pages/map_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};

  bool _isLoading = true;
  String? _error;

  // Camera initial position
  static const CameraPosition _initialCam = CameraPosition(
    target: LatLng(51.16, 71.47),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();

    // 1) Pre‐add your three static markers
    final points = <LatLng>[
      LatLng(51.17, 71.49),
      LatLng(51.15, 71.45),
      LatLng(51.18, 71.44),
    ];
    final List<List<String>> labels = [
      [
        'ZooShop on Alexandr Pushkina',
        'You can come and see the animal by address: Alexandra Pushkina 72/1',
      ],
      [
        'ZooShop on Alatau',
        'You can come and see the animal by address: Alatau complex',
      ],
      [
        'ZooShop Shapagat',
        'You can come and see the animal by address: Shapagat supermarket',
      ],
    ];

    for (var i = 0; i < points.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('static_$i'),
          position: points[i],
          infoWindow: InfoWindow(
            title: labels[i][0], // ← your custom title
            snippet: labels[i][1],
          ),
        ),
      );
    }

    // 2) Then kick off the async location work
    _addUserLocation();
  }

  Future<void> _addUserLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pos = await _determinePosition();
      final userLoc = LatLng(pos.latitude, pos.longitude);

      // Add the blue‐hued user marker
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLoc,
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );

      // Wait for the map controller (map must already be in the tree)
      final mapCtrl = await _controller.future;
      mapCtrl.animateCamera(CameraUpdate.newLatLngZoom(userLoc, 14));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _onMapCreated(GoogleMapController ctrl) {
    if (!_controller.isCompleted) {
      _controller.complete(ctrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map with Markers')),
      body: Stack(
        children: [
          // The map is always in the tree
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialCam,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // If loading, show spinner overlay
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // If error, replace spinner with message
          if (!_isLoading && _error != null)
            Center(
              child: Container(
                color: Colors.white70,
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }
}
