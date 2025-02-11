import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherContext {
  final String description;      // e.g., "light rain", "clear sky"
  final String mainCondition;    // e.g., "Rain", "Clear"
  final double temperature;      // in Celsius
  final double feelsLike;
  final int humidity;
  final DateTime sunrise;
  final DateTime sunset;
  final String timeOfDay;        // "dawn", "morning", "afternoon", "evening", "night"
  final String mood;             // Derived from conditions

  WeatherContext({
    required this.description,
    required this.mainCondition,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.sunrise,
    required this.sunset,
    required this.timeOfDay,
    required this.mood,
  });

  factory WeatherContext.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final sys = json['sys'];
    
    final now = DateTime.now();
    final sunrise = DateTime.fromMillisecondsSinceEpoch(sys['sunrise'] * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch(sys['sunset'] * 1000);

    return WeatherContext(
      description: weather['description'],
      mainCondition: weather['main'],
      temperature: main['temp'].toDouble(),
      feelsLike: main['feels_like'].toDouble(),
      humidity: main['humidity'],
      sunrise: sunrise,
      sunset: sunset,
      timeOfDay: _determineTimeOfDay(now, sunrise, sunset),
      mood: _determineWeatherMood(weather['main'], main['temp'].toDouble()),
    );
  }

  static String _determineTimeOfDay(DateTime now, DateTime sunrise, DateTime sunset) {
    final hour = now.hour;
    final sunriseHour = sunrise.hour;
    final sunsetHour = sunset.hour;

    if (hour >= sunriseHour - 1 && hour < sunriseHour + 2) return 'dawn';
    if (hour >= sunriseHour + 2 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < sunsetHour + 1) return 'evening';
    return 'night';
  }

  static String _determineWeatherMood(String condition, double temp) {
    // Create emotional context based on weather
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return 'intense';
      case 'drizzle':
      case 'rain':
        return 'melancholic';
      case 'snow':
        return 'peaceful';
      case 'clear':
        return temp > 25 ? 'energetic' : 'serene';
      case 'clouds':
        return 'contemplative';
      default:
        return 'neutral';
    }
  }

  // Get lyrical inspiration based on weather context
  String getLyricalInspiration() {
    switch (timeOfDay) {
      case 'dawn':
        return 'As the sun rises over the city, $description paints the morning sky';
      case 'morning':
        return 'Morning light breaks through the $description';
      case 'afternoon':
        return 'Under the ${mainCondition.toLowerCase()} afternoon sky';
      case 'evening':
        return 'As evening falls, the $description sets the mood';
      case 'night':
        return 'In the ${mood} night, with $description all around';
      default:
        return 'The weather tells a story of $description';
    }
  }
}

class WeatherService {
  static final String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static String? get _apiKey => dotenv.env['OPENWEATHER_API_KEY'];

  Future<WeatherContext> getCurrentWeather() async {
    try {
      // First, get current location
      final position = await _getCurrentLocation();
      
      // Then, get weather for that location
      final response = await http.get(Uri.parse(
        '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric'
      ));

      if (response.statusCode == 200) {
        return WeatherContext.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.body}');
      }
    } catch (e) {
      print('Error getting weather: $e');
      rethrow;
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permission
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

    // Get current position
    return await Geolocator.getCurrentPosition();
  }
} 