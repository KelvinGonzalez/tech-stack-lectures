import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<LatLng?> getLatLngFromAddress(String address, String apiKey) async {
  final encodedAddress = Uri.encodeComponent(address);
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded['status'] == 'OK') {
        final location = decoded['results'][0]['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        return LatLng(lat, lng);
      } else {
        print('Geocoding API Error: ${decoded['status']}');
        return null;
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error during geocoding: $e');
    return null;
  }
}

class Place {
  final String address;
  final LatLng location;
  final double? rating;
  final String name;

  const Place(this.address, this.location, this.rating, this.name);
}

Future<List<Place>> getNearbyPlaces(LatLng location, double radius,
    List<String> placeTypes, String apiKey) async {
  final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

  final headers = {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask':
        'places.displayName,places.formattedAddress,places.location,places.rating', // Specify the fields you need.
  };

  final body = jsonEncode({
    "locationRestriction": {
      "circle": {
        "center": {
          "latitude": location.latitude,
          "longitude": location.longitude,
        },
        "radius": radius,
      },
    },
    "includedTypes": placeTypes,
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded['places'] != null) {
        List<Map<String, dynamic>> results =
            List<Map<String, dynamic>>.from(decoded['places']);

        return results
            .map((e) => Place(
                e['formattedAddress'],
                LatLng(e['location']['latitude'], e['location']['longitude']),
                e['rating'],
                e['displayName']['text']))
            .toList();
      } else {
        print('Nearby Places API (New) Error: No places found or other error.');
        return [];
      }
    } else {
      print('HTTP Error (New): ${response.statusCode}');
      print(response.body);
      return [];
    }
  } catch (e) {
    print('Error during nearby search (New): $e');
    return [];
  }
}
