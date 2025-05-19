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
  final Completer<GoogleMapController> _ctrl = Completer();
  final Set<Marker> _markers = {};

  bool _isLoading = true;
  String? _errorMessage;

  // Initial camera over Astana
  static const CameraPosition _initialCam = CameraPosition(
    target: LatLng(51.16, 71.47),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  Future<void> _setupMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) Add at least three static markers
      final points = <LatLng>[
        LatLng(51.17, 71.49),
        LatLng(51.15, 71.45),
        LatLng(51.18, 71.44),
      ];
      for (var i = 0; i < points.length; i++) {
        _markers.add(Marker(
          markerId: MarkerId('static_$i'),
          position: points[i],
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        ));
      }

      // 2) Request location permission & get user location
      final position = await _determinePosition();
      final userLatLng = LatLng(position.latitude, position.longitude);

      // 3) Add a “You Are Here” marker
      _markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: userLatLng,
        infoWindow: const InfoWindow(title: 'Your location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ));

      // 4) Center map on user
      final map = await _ctrl.future;
      map.animateCamera(
        CameraUpdate.newLatLng(userLatLng),
      );
    } catch (e) {
      debugPrint('Map setup error: $e');
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Ensures permissions are granted, then returns the current position.
  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1) Still loading?
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Map with Markers')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Error during setup?
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Map with Markers')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // 3) Success! show the map
    return Scaffold(
      appBar: AppBar(title: const Text('Map with Markers')),
      body: GoogleMap(
        onMapCreated: (ctrl) => _ctrl.complete(ctrl),
        initialCameraPosition: _initialCam,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
      ),
    );
  }
}
