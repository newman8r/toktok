class UnifiedContext {
  final LocationContext location;
  final WeatherContext weather;
  final CalendarContext calendar;

  UnifiedContext({
    required this.location,
    required this.weather,
    required this.calendar,
  });
}

class LocationContext {
  final String primaryCategory;
  final String locationName;
  final List<String> vibeWords;
  final String timeContext;
  final String crowdLevel;
  final String ambiance;
  final List<String> nearbyPlaces;
  final String neighborhood;

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
}

class WeatherContext {
  final double temperature;
  final double feelsLike;
  final int pressure;
  final int humidity;
  final double dewPoint;
  final double uvi;
  final int clouds;
  final int visibility;
  final double windSpeed;
  final double? windGust;
  final int windDeg;
  final String mood;
  final String description;

  WeatherContext({
    required this.temperature,
    required this.feelsLike,
    required this.pressure,
    required this.humidity,
    required this.dewPoint,
    required this.uvi,
    required this.clouds,
    required this.visibility,
    required this.windSpeed,
    this.windGust,
    required this.windDeg,
    required this.mood,
    required this.description,
  });
}

class CalendarContext {
  final String timeOfDay;
  final String season;
  final String dayOfWeek;
  final String month;
  final int dayOfMonth;
  final int year;
  final bool isWeekend;
  final String partOfMonth;

  CalendarContext({
    required this.timeOfDay,
    required this.season,
    required this.dayOfWeek,
    required this.month,
    required this.dayOfMonth,
    required this.year,
    required this.isWeekend,
    required this.partOfMonth,
  });
} 