import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MaterialApp(home: LocationTrackingPage()));

class LocationTrackingPage extends StatefulWidget {
  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;
  List<LatLng> routePoints = [];
  LatLng? currentPosition;
  Stream<Position>? positionStream;
  bool showInfoWindow = false;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update when moved 5 meters
      ),
    );

    positionStream!.listen((Position position) {
      LatLng newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        currentPosition = newPos;
        routePoints.add(newPos);
        showInfoWindow = false;
      });

      _animatedMapController.animateTo(
        dest: newPos,
        zoom: 18,
        curve: Curves.easeInOut,
        duration: const Duration(seconds: 1),
      );
    });
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Location Tracker")),
      body: currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: currentPosition!,
              initialZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPosition!,
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showInfoWindow = true;
                        });
                      },
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (showInfoWindow && currentPosition != null)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 100,
              bottom: 140,
              child: Card(
                elevation: 6,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("My current location", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Lat: ${currentPosition!.latitude.toStringAsFixed(5)}"),
                      Text("Lng: ${currentPosition!.longitude.toStringAsFixed(5)}"),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
