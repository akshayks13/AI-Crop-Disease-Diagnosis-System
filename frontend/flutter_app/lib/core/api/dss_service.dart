import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Provider for the DSS (Decision Support System) service
final dssServiceProvider = Provider<DSSService>((ref) {
  return DSSService(ref.read(apiClientProvider));
});

/// Service for getting DSS advisory recommendations from the backend.
///
/// After on-device TFLite disease classification, this service sends the
/// disease label + weather data + farmer inputs to the backend DSS engine
/// to get risk-scored treatment recommendations.
class DSSService {
  final ApiClient _apiClient;

  DSSService(this._apiClient);

  /// Get DSS advisory for a diagnosed disease.
  ///
  /// [diseaseLabel] - Raw TFLite label like 'apple_apple_scab'
  /// [temperature] - Current temperature in °C (from weather)
  /// [humidity] - Current humidity % (from weather)
  /// [irrigation] - Farmer's irrigation level: 'Low', 'Moderate', 'Frequent'
  /// [waterlogged] - Whether field has been waterlogged recently
  /// [fertilizerRecent] - Whether fertilizer was applied recently
  /// [firstCycle] - Whether this is the first crop cycle in this soil
  Future<Map<String, dynamic>> getAdvisory({
    required String diseaseLabel,
    double? temperature,
    int? humidity,
    String irrigation = 'Moderate',
    bool waterlogged = false,
    bool fertilizerRecent = false,
    bool firstCycle = false,
  }) async {
    final response = await _apiClient.post(
      '/diagnosis/dss-advisory',
      data: {
        'disease_label': diseaseLabel,
        if (temperature != null) 'temperature': temperature,
        if (humidity != null) 'humidity': humidity,
        'irrigation': irrigation,
        'waterlogged': waterlogged,
        'fertilizer_recent': fertilizerRecent,
        'first_cycle': firstCycle,
      },
    );

    return response.data as Map<String, dynamic>;
  }
}
