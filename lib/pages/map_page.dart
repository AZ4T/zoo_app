import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

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

    // 1) Pre-add your three static markers with localized titles/snippets
    final points = <LatLng>[
      LatLng(51.17, 71.49),
      LatLng(51.15, 71.45),
      LatLng(51.18, 71.44),
    ];
    final shopKeys = ['shop.pushkina', 'shop.alatau', 'shop.shapagat'];
    for (var i = 0; i < points.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('static_$i'),
          position: points[i],
          infoWindow: InfoWindow(
            title: tr('$shopKeys[i].title'),
            snippet: tr('$shopKeys[i].desc'),
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

      // Add the blue-hued user marker with a localized label
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLoc,
          infoWindow: InfoWindow(title: tr('map.your_location')),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );

      // Animate camera to user location
      final mapCtrl = await _controller.future;
      mapCtrl.animateCamera(
        CameraUpdate.newLatLngZoom(userLoc, 14),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(tr('map.error_services_disabled'));
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception(tr('map.error_permission_denied'));
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(tr('map.error_permission_denied_forever'));
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
      appBar: AppBar(
        title: Text(tr('map.title')),
      ),
      body: Stack(
        children: [
          // Always show the map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialCam,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Loading spinner overlay
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Error message overlay
          if (!_isLoading && _error != null)
            Center(
              child: Container(
                color: Colors.white70,
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
