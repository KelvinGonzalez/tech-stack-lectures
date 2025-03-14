import 'dart:async';

import 'package:untitled/maps_api/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const API_KEY = "Insert your own API key here";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng position = const LatLng(0, 0);
  Completer<GoogleMapController> mapController = Completer();
  List<Place> places = [];
  Polyline? polyline;
  int currentPlace = 0;

  Future<void> search(String address) async {
    final controller = await mapController.future;
    final location = await getLatLngFromAddress(address, API_KEY);
    if (location != null) {
      controller.animateCamera(CameraUpdate.newLatLng(location));
      position = location;
      places = await getNearbyPlaces(
          position, 1000, ["grocery_store", "convenience_store"], API_KEY);
      if (places.isNotEmpty) {
        polyline = await getPolyline(position, places.first.location);
      }
      currentPlace = 0;
      setState(() {});
    }
  }

  Future<Polyline> getPolyline(LatLng from, LatLng to) async {
    final result = await PolylinePoints().getRouteBetweenCoordinates(
        request: PolylineRequest(
            origin: PointLatLng(from.latitude, from.longitude),
            destination: PointLatLng(to.latitude, to.longitude),
            mode: TravelMode.walking),
        googleApiKey: API_KEY);
    return Polyline(
        polylineId: PolylineId("$from,$to"),
        points:
            result.points.map((e) => LatLng(e.latitude, e.longitude)).toList());
  }

  Future<void> changePlace(int direction /*Either -1 or 1*/) async {
    if (direction != -1 && direction != 1) return;
    if (direction < 0 && currentPlace == 0) return;
    if (direction > 0 && currentPlace == places.length - 1) return;
    currentPlace += direction;
    polyline = await getPolyline(position, places[currentPlace].location);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    search("University of Puerto Rico Mayaguez");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onSubmitted: (value) {
                    search(value);
                  },
                ),
              ),
              IconButton(
                  onPressed: () => changePlace(-1),
                  icon: const Icon(Icons.arrow_back)),
              IconButton(
                  onPressed: () => changePlace(1),
                  icon: const Icon(Icons.arrow_forward)),
            ],
          ),
          Expanded(
              child: GoogleMap(
            markers: {
              Marker(markerId: const MarkerId("init"), position: position),
            }.union(places
                .map((e) =>
                    Marker(markerId: MarkerId(e.name), position: e.location))
                .toSet()),
            initialCameraPosition: CameraPosition(target: position, zoom: 16),
            onMapCreated: (controller) => mapController.complete(controller),
            polylines: {if (polyline != null) polyline!},
          )),
        ],
      ),
    );
  }
}
