import 'package:intl/intl.dart';
import 'weather_service.dart';
import 'places_service.dart';

class CalendarContext {
  final String dayOfWeek;
  final String month;
  final int dayOfMonth;
  final int year;
  final String season;
  final bool isWeekend;
  final String timeOfDay;
  final String partOfMonth; // "beginning", "middle", "end"

  CalendarContext._({
    required this.dayOfWeek,
    required this.month,
    required this.dayOfMonth,
    required this.year,
    required this.season,
    required this.isWeekend,
    required this.timeOfDay,
    required this.partOfMonth,
  });

  factory CalendarContext.now() {
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

    return CalendarContext._(
      dayOfWeek: formatter.format(now),
      month: monthFormatter.format(now),
      dayOfMonth: now.day,
      year: now.year,
      season: season,
      isWeekend: now.weekday >= 6,
      timeOfDay: timeOfDay,
      partOfMonth: partOfMonth,
    );
  }

  String getLyricalInspiration() {
    if (isWeekend) {
      return 'Weekend $timeOfDay in $month, when the world slows down';
    } else {
      return '$dayOfWeek $timeOfDay, as the $season breeze flows';
    }
  }

  String suggestMusicStyle() {
    if (isWeekend && (timeOfDay == 'night' || timeOfDay == 'evening')) {
      return 'Party';
    } else if (season == 'winter') {
      return 'Lo-fi';
    } else if (season == 'summer' && timeOfDay == 'afternoon') {
      return 'Modern';
    } else if (timeOfDay == 'morning') {
      return 'Chill';
    }
    return 'Melodic';
  }
}

class UnifiedContext {
  final WeatherContext weather;
  final LocationContext location;
  final CalendarContext calendar;

  UnifiedContext({
    required this.weather,
    required this.location,
    required this.calendar,
  });

  String generateLyricalTheme() {
    // Combine all contexts for rich lyrical inspiration
    final themes = [
      weather.getLyricalInspiration(),
      location.getLyricalInspiration(),
      calendar.getLyricalInspiration(),
    ];

    // Randomly select two themes to combine
    themes.shuffle();
    return '${themes[0]} • ${themes[1]}';
  }

  String determineMusicStyle() {
    // Weight the suggestions from each context
    final styles = {
      weather.mood: 2,  // Weather mood has strong influence
      location.suggestMusicStyle(): 3,  // Location is primary factor
      calendar.suggestMusicStyle(): 1,  // Calendar adds subtle influence
    };

    // Count weighted votes
    final voteCounts = <String, int>{};
    styles.forEach((style, weight) {
      voteCounts[style] = (voteCounts[style] ?? 0) + weight;
    });

    // Return style with most votes
    return voteCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Map<String, dynamic> toJson() {
    return {
      'weather': {
        'condition': weather.mainCondition,
        'mood': weather.mood,
        'timeOfDay': weather.timeOfDay,
      },
      'location': {
        'type': location.primaryCategory,
        'name': location.locationName,
        'vibe': location.vibeWords,
        'ambiance': location.ambiance,
      },
      'calendar': {
        'dayOfWeek': calendar.dayOfWeek,
        'season': calendar.season,
        'timeOfDay': calendar.timeOfDay,
        'isWeekend': calendar.isWeekend,
      },
    };
  }
}

class ContextualMusicService {
  final WeatherService _weatherService;
  final PlacesService _placesService;

  ContextualMusicService()
      : _weatherService = WeatherService(),
        _placesService = PlacesService();

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

      // Create unified context
      return UnifiedContext(
        weather: results[0] as WeatherContext,
        location: results[1] as LocationContext,
        calendar: CalendarContext.now(),
      );
    } catch (e) {
      print('❌ Error gathering context: $e');
      rethrow;
    }
  }
} 