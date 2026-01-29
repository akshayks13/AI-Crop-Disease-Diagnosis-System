import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherData {
  final String cityName;
  final double temp;
  final String description;
  final int humidity;
  final double windSpeed;
  final String iconCode;
  final DateTime date;

  WeatherData({
    required this.cityName,
    required this.temp,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.iconCode,
    required this.date,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? '',
      temp: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      iconCode: json['weather'][0]['icon'],
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }
}

class ForecastData {
  final DateTime dt;
  final double temp;
  final String icon;
  final String description;

  ForecastData({
    required this.dt,
    required this.temp,
    required this.icon,
    required this.description,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      dt: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temp: (json['main']['temp'] as num).toDouble(),
      icon: json['weather'][0]['icon'],
      description: json['weather'][0]['description'],
    );
  }
}

class WeatherService {
  // Fetch API Key from .env
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<WeatherData> getCurrentWeather() async {
    try {
      final position = await _determinePosition();
      final url = '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      // Fallback for demo/testing if location fails or on emulator without location
      // Or rethrow to handle in UI
      throw Exception('Error fetching weather: $e');
    }
  }

  Future<List<ForecastData>> getHourlyForecast() async {
    try {
      final position = await _determinePosition();
      final url = '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['list'] as List).map((item) => ForecastData.fromJson(item)).toList();
        return list; // OpenWeatherMap forecast returns 3-hour intervals
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }
  
  Future<WeatherData> getCityWeather(String cityName) async {
     final url = '$_baseUrl/weather?q=$cityName&units=metric&appid=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data for $cityName');
      }
  }
}
