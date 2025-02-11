import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationContext {
  final String primaryCategory;    // e.g., "Park", "Restaurant", "Beach"
  final String locationName;       // Name of the most prominent nearby place
  final List<String> vibeWords;    // e.g., ["bustling", "urban", "peaceful"]
  final String timeContext;        // e.g., "lunch hour", "late night"
  final String crowdLevel;         // e.g., "busy", "quiet"
  final String ambiance;           // e.g., "romantic", "energetic"
  final List<String> nearbyPlaces; // Names of other notable places
  final String neighborhood;       // Name of the neighborhood/district

  LocationContext({
    required this.primaryCategory,
    required this.locationName,
    required this.vibeWords,
    required this.timeContext,
    required this.crowdLevel,
    required this.ambiance,
    required this.nearbyPlaces,
    required this.neighborhood,
  });

  // Get lyrical inspiration based on location context
  String getLyricalInspiration() {
    final random = DateTime.now().millisecond % 5; // For variety in responses
    switch (random) {
      case 0:
        return 'Down in the $neighborhood, where the $ambiance vibe flows';
      case 1:
        return 'At $locationName, feeling that ${vibeWords.first} energy';
      case 2:
        return '$timeContext in the city, ${crowdLevel.toLowerCase()} streets tell stories';
      case 3:
        return 'From $locationName to ${nearbyPlaces.first}, the rhythm of the city beats';
      default:
        return 'In this $ambiance corner of $neighborhood, where dreams take flight';
    }
  }

  // Combine with weather for richer context
  String combineWithWeather(String weatherMood) {
    return '$timeContext in $neighborhood, $weatherMood skies above $locationName';
  }

  // Get musical style suggestion based on location
  String suggestMusicStyle() {
    // Map location characteristics to music styles
    if (crowdLevel == 'busy' && ambiance == 'energetic') {
      return 'Modern';
    } else if (ambiance == 'romantic' || timeContext == 'late night') {
      return 'Lo-fi';
    } else if (vibeWords.contains('urban') || vibeWords.contains('bustling')) {
      return 'Hip Hop';
    } else if (primaryCategory == 'Beach' || primaryCategory == 'Park') {
      return 'Chill';
    } else {
      return 'Melodic';
    }
  }
}

class PlacesService {
  static final String _baseUrl = 'https://api.foursquare.com/v3';
  static String? get _apiKey => dotenv.env['FOURSQUARE_API_KEY'];
  
  Future<LocationContext> getCurrentLocationContext() async {
    try {
      print('🌍 Getting current location context...');
      final position = await _getCurrentLocation();
      
      // Get nearby places
      final places = await _getNearbyPlaces(position);
      if (places.isEmpty) {
        throw Exception('No places found nearby');
      }

      // Get primary place details
      final primaryPlace = places.first;
      final placeDetails = await _getPlaceDetails(primaryPlace['fsq_id']);

      // Extract neighborhood
      final neighborhood = _extractNeighborhood(placeDetails);

      // Determine time context
      final timeContext = _determineTimeContext();

      // Generate vibe words based on place attributes
      final vibeWords = _generateVibeWords(placeDetails, places);

      // Determine crowd level (could be enhanced with actual Foursquare popularity data)
      final crowdLevel = _determineCrowdLevel(timeContext, primaryPlace['categories']?.first['name']);

      // Create location context
      return LocationContext(
        primaryCategory: primaryPlace['categories']?.first['name'] ?? 'Unknown',
        locationName: primaryPlace['name'],
        vibeWords: vibeWords,
        timeContext: timeContext,
        crowdLevel: crowdLevel,
        ambiance: _determineAmbiance(vibeWords, timeContext),
        nearbyPlaces: places.skip(1).take(3).map((p) => p['name'] as String).toList(),
        neighborhood: neighborhood,
      );

    } catch (e) {
      print('❌ Error getting location context: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getNearbyPlaces(Position position) async {
    if (_apiKey == null) {
      throw Exception('Foursquare API key not found in environment variables');
    }

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/places/search?ll=${position.latitude},${position.longitude}&sort=DISTANCE&limit=10'
      ),
      headers: {
        'Authorization': _apiKey!,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Failed to load nearby places: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getPlaceDetails(String placeId) async {
    if (_apiKey == null) {
      throw Exception('Foursquare API key not found in environment variables');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/places/$placeId'),
      headers: {
        'Authorization': _apiKey!,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load place details: ${response.body}');
    }
  }

  String _extractNeighborhood(Map<String, dynamic> placeDetails) {
    try {
      final location = placeDetails['location'];
      return location['neighborhood']?.first ?? 
             location['crossStreet'] ?? 
             location['locality'] ?? 
             'the city';
    } catch (e) {
      return 'the city';
    }
  }

  String _determineTimeContext() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'morning';
    if (hour >= 11 && hour < 14) return 'lunch hour';
    if (hour >= 14 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 20) return 'evening';
    if (hour >= 20 && hour < 23) return 'night';
    return 'late night';
  }

  List<String> _generateVibeWords(Map<String, dynamic> placeDetails, List<Map<String, dynamic>> nearbyPlaces) {
    final vibeWords = <String>{};
    
    // Add words based on the primary place
    final categories = placeDetails['categories'] ?? [];
    for (final category in categories) {
      final name = category['name'].toString().toLowerCase();
      if (name.contains('restaurant')) vibeWords.add('culinary');
      if (name.contains('park')) vibeWords.add('peaceful');
      if (name.contains('bar')) vibeWords.add('lively');
      if (name.contains('cafe')) vibeWords.add('cozy');
      if (name.contains('museum')) vibeWords.add('cultural');
    }

    // Add words based on nearby places density
    if (nearbyPlaces.length > 5) {
      vibeWords.add('bustling');
    } else {
      vibeWords.add('tranquil');
    }

    // Add urban/suburban context
    if (placeDetails['location']?['neighborhood'] != null) {
      vibeWords.add('urban');
    } else {
      vibeWords.add('suburban');
    }

    // Ensure we have at least 3 vibe words
    final defaultVibes = ['vibrant', 'dynamic', 'atmospheric'];
    for (final vibe in defaultVibes) {
      if (vibeWords.length < 3) vibeWords.add(vibe);
    }

    return vibeWords.take(3).toList();
  }

  String _determineCrowdLevel(String timeContext, String? category) {
    // Time-based crowd level
    if (timeContext == 'morning' || timeContext == 'late night') {
      return 'quiet';
    }
    if (timeContext == 'lunch hour' || timeContext == 'evening') {
      return 'busy';
    }

    // Category-based crowd level
    if (category != null) {
      category = category.toLowerCase();
      if (category.contains('park') || category.contains('museum')) {
        return 'moderate';
      }
      if (category.contains('restaurant') || category.contains('bar')) {
        return 'busy';
      }
    }

    return 'moderate';
  }

  String _determineAmbiance(List<String> vibeWords, String timeContext) {
    if (vibeWords.contains('peaceful') || vibeWords.contains('tranquil')) {
      return 'serene';
    }
    if (vibeWords.contains('lively') || vibeWords.contains('bustling')) {
      return 'energetic';
    }
    if (timeContext == 'night' || timeContext == 'evening') {
      return 'romantic';
    }
    if (vibeWords.contains('cultural') || vibeWords.contains('cozy')) {
      return 'sophisticated';
    }
    return 'vibrant';
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }
} 