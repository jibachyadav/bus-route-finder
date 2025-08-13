import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteUtils {
  /// Method to draw a route on the map from Firestore
  static Future<void> drawRoute({
    required String? startingPoint,
    required String? destination,
    required Marker? currentLocationMarker,
    required void Function(Set<Polyline> polylines, Set<Marker> markers, List<String> buses) onUpdate,
  }) async {
    if (startingPoint == null || destination == null || startingPoint == destination ) {
      onUpdate({}, {}, []);
      return;
    }

    try {
      final BitmapDescriptor stopIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(74, 74)),
        'assets/bus2.png',
      );

      final query = await FirebaseFirestore.instance
          .collection('route')
          .where('start', isEqualTo: startingPoint)
          .where('end', isEqualTo: destination)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        onUpdate({}, {}, []);
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      debugPrint("Firestore route data: $data");

      final List<dynamic> coordData = data['coordinates'];
      final List<dynamic> stopData = data['stops'];
      final String busName = data['bus'];

      final List<LatLng> routeCoordinates = coordData
          .map((point) => LatLng(point['Lat'], point['Lng']))
          .toList();

      final Set<Marker> markers = {};
      final Set<Polyline> polylines = {
        Polyline(
          polylineId: const PolylineId("route_polyline"),
          points: routeCoordinates,
          color: Colors.blue,
          width: 8,
        ),
      };

      markers.add(Marker(
        markerId: const MarkerId("start_marker"),
        position: routeCoordinates.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: startingPoint),
      ));

      markers.add(Marker(
        markerId: const MarkerId("end_marker"),
        position: routeCoordinates.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: destination),
      ));

      for (var stop in stopData) {
        markers.add(Marker(
          markerId: MarkerId(stop['title']),
          position: LatLng(stop['Lat'], stop['Lng']),
          icon: stopIcon,
          infoWindow: InfoWindow(title: stop['title']),
        ));
      }

      if (currentLocationMarker != null) {
        markers.add(currentLocationMarker);
      }

      onUpdate(polylines, markers, [busName]);
    } catch (e) {
      debugPrint("Error loading route from Firestore: $e");
      onUpdate({}, {}, []);
    }
  }

  /// Method to save a new route to Firestore
  static Future<void> saveRoute({
    required String start,
    required String end,
    required String bus,
    required List<Map<String, dynamic>> coordinates,
    required List<Map<String, dynamic>> stops,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('route').add({
        'start': start,
        'end': end,
        'bus': bus,
        'coordinates': coordinates,
        'stops': stops,
      });
      debugPrint("Route saved successfully.");
    } catch (e) {
      debugPrint("Error saving route to Firestore: $e");
    }
  }
}
