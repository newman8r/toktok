import 'package:intl/intl.dart';
import 'weather_service.dart' hide WeatherContext;
import 'places_service.dart' hide LocationContext;
import '../models/unified_context.dart';

class ContextualMusicService {
  final WeatherService _weatherService;
  final PlacesService _placesService;

  ContextualMusicService()
      : _weatherService = WeatherService(),
        _placesService = PlacesService();

  String _getLyricalInspiration(CalendarContext calendar) {
    if (calendar.isWeekend) {
      return 'Weekend ${calendar.timeOfDay} in ${calendar.month}, when the world slows down';
    } else {
      return '${calendar.dayOfWeek} ${calendar.timeOfDay}, as the ${calendar.season} breeze flows';
    }
  }

  String _suggestMusicStyle(CalendarContext calendar) {
    if (calendar.isWeekend && (calendar.timeOfDay == 'night' || calendar.timeOfDay == 'evening')) {
      return 'Party';
    } else if (calendar.season == 'winter') {
      return 'Lo-fi';
    } else if (calendar.season == 'summer' && calendar.timeOfDay == 'afternoon') {
      return 'Modern';
    } else if (calendar.timeOfDay == 'morning') {
      return 'Chill';
    }
    return 'Melodic';
  }

  Future<UnifiedContext> getUnifiedContext() async {
    try {
      print('🎭 Gathering contextual information...');
      
      // Gather all contexts in parallel
      final weatherFuture = _weatherService.getCurrentWeather();
      final locationFuture = _placesService.getCurrentLocationContext();
      
      // Wait for all contexts
      final results = await Future.wait([
        weatherFuture,
        locationFuture,
      ]);

      final weatherData = results[0] as dynamic;
      final locationData = results[1] as dynamic;

      // Convert weather data to our unified WeatherContext model
      final weather = WeatherContext(
        temperature: weatherData.temperature,
        feelsLike: weatherData.feelsLike,
        humidity: weatherData.humidity,
        dewPoint: 0.0,  // Default value since not available
        uvi: 0.0,      // Default value since not available
        clouds: 0,      // Default value since not available
        visibility: 10000, // Default good visibility
        windSpeed: 0.0,   // Default value since not available
        windGust: null,   // Default value since not available
        windDeg: 0,       // Default value since not available
        mood: weatherData.mood,
        description: weatherData.description,
      );

      // Convert location data to our unified LocationContext model
      final location = LocationContext(
        primaryCategory: locationData.primaryCategory,
        locationName: locationData.locationName,
        vibeWords: locationData.vibeWords,
        timeContext: locationData.timeContext,
        crowdLevel: locationData.crowdLevel,
        ambiance: locationData.ambiance,
        nearbyPlaces: locationData.nearbyPlaces,
        neighborhood: locationData.neighborhood,
      );

      final now = DateTime.now();
      final formatter = DateFormat('EEEE');
      final monthFormatter = DateFormat('MMMM');
      
      // Determine season
      final month = now.month;
      final day = now.day;
      String season;
      if ((month == 12 && day >= 21) || month <= 2 || (month == 3 && day < 20)) {
        season = 'winter';
      } else if ((month == 3 && day >= 20) || month <= 5 || (month == 6 && day < 21)) {
        season = 'spring';
      } else if ((month == 6 && day >= 21) || month <= 8 || (month == 9 && day < 22)) {
        season = 'summer';
      } else {
        season = 'autumn';
      }

      // Determine part of month
      String partOfMonth;
      if (day <= 10) {
        partOfMonth = 'beginning';
      } else if (day <= 20) {
        partOfMonth = 'middle';
      } else {
        partOfMonth = 'end';
      }

      // Determine time of day
      final hour = now.hour;
      String timeOfDay;
      if (hour >= 5 && hour < 12) {
        timeOfDay = 'morning';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'afternoon';
      } else if (hour >= 17 && hour < 21) {
        timeOfDay = 'evening';
      } else {
        timeOfDay = 'night';
      }

      // Create unified context
      final context = UnifiedContext(
        weather: weather,
        location: location,
        calendar: CalendarContext(
          timeOfDay: timeOfDay,
          season: season,
          dayOfWeek: formatter.format(now),
          month: monthFormatter.format(now),
          dayOfMonth: now.day,
          year: now.year,
          isWeekend: now.weekday >= DateTime.saturday,
          partOfMonth: partOfMonth,
        ),
      );

      return context;
    } catch (e) {
      print('❌ Error gathering context: $e');
      rethrow;
    }
  }
} 