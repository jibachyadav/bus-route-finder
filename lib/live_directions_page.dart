import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveDirectionsPage extends StatefulWidget {
  final LatLng start;
  final LatLng end;

  const LiveDirectionsPage({super.key, required this.start, required this.end});

  @override
  State<LiveDirectionsPage> createState() => _LiveDirectionsPageState();
}

class _LiveDirectionsPageState extends State<LiveDirectionsPage> {
  List<String> steps = [];

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  Future<void> _fetchDirections() async {
    const apiKey = 'AIzaSyCFuj8wRsC-TXcrB0OAGo7IZoiLjOitUVw'; // Replace with your actual key

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.start.latitude},${widget.start.longitude}&destination=${widget.end.latitude},${widget.end.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final stepsList = data['routes'][0]['legs'][0]['steps'] as List;
      setState(() {
        steps = stepsList.map((step) => _removeHtmlTags(step['html_instructions'])).toList();
      });
    } else {
      setState(() {
        steps = ['Failed to fetch directions'];
      });
    }
  }

  String _removeHtmlTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Directions")),
      body: steps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(steps[index]),
        ),
      ),
    );
  }
}
