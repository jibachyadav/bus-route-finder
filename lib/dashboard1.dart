import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'login_page.dart';
import 'route_utils.dart';

class Dashboard1 extends StatefulWidget {
  const Dashboard1({super.key});

  @override
  State<Dashboard1> createState() => _Dashboard1State();
}

class _Dashboard1State extends State<Dashboard1> {
  String? startingPoint;
  String? destination;
  GoogleMapController? _mapController;

  List<String> locations = [
    'Maitidevi',
    'Gongabu New Bus Station Parking, Kathmandu 44600',
    'Lagankhel',
    'Kalanki',
    'Bhaktapur(sanothimi)',
  ];

  final Map<String, LatLng> locationCoords = {
    'Maitidevi': LatLng(27.706056, 85.333793),
    'Gongabu New Bus Station Parking, Kathmandu 44600': LatLng(27.735070, 85.308410),
    'Lagankhel': LatLng(27.6647, 85.3185),
    'Kalanki': LatLng(27.693180, 85.280717),
    'Bhaktapur(sanothimi)': LatLng(27.674784, 85.427371),
  };

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LocationData? _currentLocation;
  Location _location = Location();
  Marker? _currentLocationMarker;

  List<String> busesOnRoute = [];

  @override
  void initState() {
    super.initState();
  }

  void _swapRoute() {
    final temp = startingPoint;
    setState(() {
      startingPoint = destination;
      destination = temp;
      busesOnRoute.clear();
    });
  }

  void _drawRoute() {
    if (startingPoint == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both start and destination.")),
      );
      return;
    }

    RouteUtils.drawRoute(
      startingPoint: startingPoint!,
      destination: destination!,
      // locationCoords: locationCoords,
      currentLocationMarker: _currentLocationMarker,
      onUpdate: (newPolylines, newMarkers, buses) {
        setState(() {
          _polylines = newPolylines;
          _markers = newMarkers;
          busesOnRoute = buses;
        });
        final startLatLng = locationCoords[startingPoint!];
        if (startLatLng != null) {
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(startLatLng, 13));
        }
      },
    );
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _markers.clear();
      _currentLocationMarker = null;
      startingPoint = null;
      destination = null;
      busesOnRoute.clear();
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _currentLocation = await _location.getLocation();
    if (_currentLocation == null) return;

    LatLng userPos = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    _currentLocationMarker = Marker(
      markerId: const MarkerId("current_location"),
      position: userPos,
      infoWindow: const InfoWindow(title: "You are here"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    if (!locations.contains("Current Location")) {
      locations.insert(0, "Current Location");
    }
    locationCoords["Current Location"] = userPos;

    String? matchedLocation = _matchLocationToPredefined(userPos);

    setState(() {
      startingPoint = matchedLocation ?? "Current Location";
      _markers.add(_currentLocationMarker!);
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(userPos));
  }

  String? _matchLocationToPredefined(LatLng userPos, {double threshold = 0.001}) {
    for (var entry in locationCoords.entries) {
      final double distance = _distance(userPos, entry.value);
      if (distance <= threshold) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _findNearestStop() async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
    }
    if (_currentLocation == null || _markers.isEmpty) return;

    LatLng user = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    List<Marker> stops = _markers.where((m) => m.markerId.value != "current_location").toList();
    stops.sort((a, b) => _distance(user, a.position).compareTo(_distance(user, b.position)));
    Marker nearest = stops.first;

    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId("nearest_stop"),
        position: nearest.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: "Nearest Stop"),
      ));
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(nearest.position));
  }

  double _distance(LatLng a, LatLng b) {
    return sqrt(pow(a.latitude - b.latitude, 2) + pow(a.longitude - b.longitude, 2));
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Route Finder', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(27.7172, 85.3240),
                      zoom: 12,
                    ),
                    polylines: _polylines,
                    markers: _markers,
                    onMapCreated: (c) => _mapController = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: busesOnRoute.isNotEmpty
                    ? Card(
                  key: const ValueKey("busInfo"),
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.teal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Bus(es) on this route: ${busesOnRoute.join(', ')}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Padding(
                  key: const ValueKey("noBusInfo"),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "No bus info available for this route.",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(showSearchBox: true),
                items: locations,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Starting Point",
                    prefixIcon: const Icon(Icons.location_on),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                selectedItem: startingPoint,
                onChanged: (val) => setState(() => startingPoint = val),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _swapRoute,
                  icon: const Icon(Icons.swap_vert, size: 32),
                  label: const Text(""),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(showSearchBox: true),
                items: locations,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Destination",
                    prefixIcon: const Icon(Icons.flag),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                selectedItem: destination,
                onChanged: (val) => setState(() => destination = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _drawRoute,
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text("Show Route", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearRoute,
                      icon: const Icon(Icons.clear, color: Colors.white),
                      label: const Text("Clear", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("My Location"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: BorderSide(color: Colors.teal.shade700),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _findNearestStop,
                    icon: const Icon(Icons.near_me),
                    label: const Text("Nearest Stop"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: BorderSide(color: Colors.teal.shade700),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}