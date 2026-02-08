import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Provider for the Agronomy service
final agronomyServiceProvider = Provider<AgronomyService>((ref) {
  return AgronomyService(ref.read(apiClientProvider));
});

/// Service for agronomy intelligence features
class AgronomyService {
  final ApiClient _apiClient;

  AgronomyService(this._apiClient);

  /// Validate a disease diagnosis against environmental context
  Future<Map<String, dynamic>> validateDiagnosis({
    required String diseaseId,
    String? cropId,
    double? temperature,
    double? humidity,
    double? rainfall,
    String? soilType,
    String? season,
    String? region,
  }) async {
    final response = await _apiClient.post(
      '/agronomy/validate-diagnosis',
      data: {
        'disease_id': diseaseId,
        if (cropId != null) 'crop_id': cropId,
        'context': {
          if (temperature != null) 'temperature': temperature,
          if (humidity != null) 'humidity': humidity,
          if (rainfall != null) 'rainfall': rainfall,
          if (soilType != null) 'soil_type': soilType,
          if (season != null) 'season': season,
          if (region != null) 'region': region,
        },
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Check treatment safety given environmental conditions
  Future<Map<String, dynamic>> checkTreatmentSafety({
    required String treatmentName,
    required String treatmentType,
    double? temperature,
    double? humidity,
    double? rainfall,
    String? soilType,
    String? season,
    String? region,
    String? cropStage,
  }) async {
    final response = await _apiClient.post(
      '/agronomy/check-safety',
      data: {
        'treatment_name': treatmentName,
        'treatment_type': treatmentType,
        'context': {
          if (temperature != null) 'temperature': temperature,
          if (humidity != null) 'humidity': humidity,
          if (rainfall != null) 'rainfall': rainfall,
          if (soilType != null) 'soil_type': soilType,
          if (season != null) 'season': season,
          if (region != null) 'region': region,
        },
        if (cropStage != null) 'crop_stage': cropStage,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Get diseases prevalent in a specific season and region
  Future<List<Map<String, dynamic>>> getSeasonalDiseases({
    required String cropId,
    required String season,
    String? region,
  }) async {
    final response = await _apiClient.get(
      '/agronomy/seasonal-diseases',
      queryParameters: {
        'crop_id': cropId,
        'season': season,
        if (region != null) 'region': region,
      },
    );

    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
