import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Market price data model
class MarketPrice {
  final String id;
  final String commodity;
  final double price;
  final String unit;
  final String location;
  final String trend;
  final double changePercent;
  final DateTime recordedAt;

  MarketPrice({
    required this.id,
    required this.commodity,
    required this.price,
    required this.unit,
    required this.location,
    required this.trend,
    required this.changePercent,
    required this.recordedAt,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: json['id'] ?? '',
      commodity: json['commodity'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? 'Quintal',
      location: json['location'] ?? '',
      trend: json['trend'] ?? 'stable',
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0,
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

  MarketState({
    this.prices = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.locationFilter,
  });

  MarketState copyWith({
    List<MarketPrice>? prices,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? locationFilter,
  }) {
    return MarketState(
      prices: prices ?? this.prices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      locationFilter: locationFilter ?? this.locationFilter,
    );
  }

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

  Future<void> loadPrices() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _api.get(ApiConfig.marketPrices);
      final data = response.data as Map<String, dynamic>;
      final pricesList = (data['prices'] as List)
          .map((p) => MarketPrice.fromJson(p))
          .toList();
      
      state = state.copyWith(prices: pricesList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setLocationFilter(String? location) {
    state = state.copyWith(locationFilter: location);
    loadPrices(); // Reload with filter
  }

  Future<void> refresh() => loadPrices();
}

/// Provider for market prices
final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  final api = ref.watch(apiClientProvider);
  return MarketNotifier(api);
});
