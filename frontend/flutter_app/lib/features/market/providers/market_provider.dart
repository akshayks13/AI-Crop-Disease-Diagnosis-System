import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/utils/app_logger.dart';

/// Market price data model
class MarketPrice {
  final String id;
  final String commodity;
  final double price;
  final String unit;
  final String location;
  final String trend;
  final double changePercent;
  final double? minPrice;
  final double? maxPrice;
  final double? arrivalQty;
  final DateTime recordedAt;

  MarketPrice({
    required this.id,
    required this.commodity,
    required this.price,
    required this.unit,
    required this.location,
    required this.trend,
    required this.changePercent,
    this.minPrice,
    this.maxPrice,
    this.arrivalQty,
    required this.recordedAt,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: json['id']?.toString() ?? '',
      commodity: json['commodity']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? 'Quintal',
      location: json['location']?.toString() ?? '',
      trend: json['trend']?.toString() ?? 'stable',
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      arrivalQty: (json['arrival_qty'] as num?)?.toDouble(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'])
          : DateTime.now(),
    );
  }

  String get changeString {
    if (changePercent > 0) return '+${changePercent.toStringAsFixed(1)}%';
    if (changePercent < 0) return '${changePercent.toStringAsFixed(1)}%';
    return '0%';
  }
}

/// Market prices state
class MarketState {
  final List<MarketPrice> prices;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? locationFilter;

  // Location detection
  final bool isLocating;
  final String? detectedCity;      // e.g. "Bengaluru"
  final String? detectedDistrict;  // e.g. "Bangalore Urban"
  final String? locationError;

  MarketState({
    this.prices = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.locationFilter,
    this.isLocating = false,
    this.detectedCity,
    this.detectedDistrict,
    this.locationError,
  });

  MarketState copyWith({
    List<MarketPrice>? prices,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? locationFilter,
    bool? isLocating,
    String? detectedCity,
    String? detectedDistrict,
    String? locationError,
  }) {
    return MarketState(
      prices: prices ?? this.prices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      locationFilter: locationFilter ?? this.locationFilter,
      isLocating: isLocating ?? this.isLocating,
      detectedCity: detectedCity ?? this.detectedCity,
      detectedDistrict: detectedDistrict ?? this.detectedDistrict,
      locationError: locationError,
    );
  }

  /// Whether location-based filtering is active
  bool get isNearMeActive => locationFilter != null && locationFilter!.isNotEmpty;

  /// Display label for the active location
  String get locationDisplayName => detectedCity ?? detectedDistrict ?? locationFilter ?? '';

  List<MarketPrice> get filteredPrices {
    var result = prices;
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((p) =>
        p.commodity.toLowerCase().contains(query) ||
        p.location.toLowerCase().contains(query)
      ).toList();
    }
    return result;
  }
}

/// Market prices notifier
class MarketNotifier extends StateNotifier<MarketState> {
  final ApiClient _api;

  MarketNotifier(this._api) : super(MarketState()) {
    loadPrices();
  }

  Future<void> loadPrices({String? location}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final loc = location ?? state.locationFilter;
      final queryParams = loc != null && loc.isNotEmpty
          ? '${ApiConfig.marketPrices}?page_size=10&location=${Uri.encodeComponent(loc)}'
          : '${ApiConfig.marketPrices}?page_size=10';

      AppLogger.info('Loading market prices', tag: 'Market');
      final response = await _api.get(queryParams);
      final data = response.data as Map<String, dynamic>;
      final pricesList = (data['prices'] as List)
          .map((p) => MarketPrice.fromJson(p))
          .toList();

      AppLogger.info('Loaded ${pricesList.length} prices', tag: 'Market');
      state = state.copyWith(prices: pricesList, isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to load market prices', tag: 'Market', error: e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Detect current location and load nearby market prices
  Future<void> loadPricesNearMe() async {
    // Location detection is not supported on web
    if (kIsWeb) {
      state = state.copyWith(
        isLocating: false,
        locationError:
            'Location detection is not available in the browser. Use the search bar to filter by city.',
      );
      return;
    }

    state = state.copyWith(isLocating: true, locationError: null);
    AppLogger.info('Detecting location for market prices', tag: 'Market');

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLocating: false,
          locationError: 'Location permission denied. Grant permission in Settings.',
        );
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // Low accuracy is enough for city-level
          timeLimit: Duration(seconds: 10),
        ),
      );

      AppLogger.info(
        'Got position: ${position.latitude}, ${position.longitude}',
        tag: 'Market',
      );

      // Reverse geocode to get city name
      String? cityName;
      String? districtName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Use locality (city) or subAdministrativeArea (district)
          cityName = place.locality?.isNotEmpty == true ? place.locality : null;
          districtName = place.subAdministrativeArea?.isNotEmpty == true
              ? place.subAdministrativeArea
              : null;
          AppLogger.info(
            'Detected: city=$cityName, district=$districtName',
            tag: 'Market',
          );
        }
      } catch (e) {
        AppLogger.warning('Reverse geocoding failed, using coordinates', tag: 'Market', error: e);
      }

      // Use city name as location filter, fall back to district
      final filterLocation = cityName ?? districtName;

      state = state.copyWith(
        isLocating: false,
        detectedCity: cityName,
        detectedDistrict: districtName,
        locationFilter: filterLocation,
      );

      // Reload prices with location filter
      await loadPrices(location: filterLocation);
    } catch (e) {
      AppLogger.error('Location detection failed', tag: 'Market', error: e);
      state = state.copyWith(
        isLocating: false,
        locationError: 'Could not detect location. Check GPS settings.',
      );
    }
  }

  /// Clear location filter and show all prices
  Future<void> clearLocationFilter() async {
    state = state.copyWith(
      locationFilter: null,
      detectedCity: null,
      detectedDistrict: null,
      locationError: null,
    );
    await loadPrices();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() => loadPrices();
}

/// Provider for market prices
final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  final api = ref.watch(apiClientProvider);
  return MarketNotifier(api);
});
