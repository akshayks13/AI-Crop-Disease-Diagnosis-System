import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';

/// Mobile ML service uses backend inference only.
class MLService {
  final Ref ref;

  MLService(this.ref);

  Future<void> initialize() async {
    // Backend-only mode: no local TFLite interpreter initialization.
    debugPrint('MLService (Mobile): backend-only mode initialized');
  }

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.uploadFileBytes(
        ApiConfig.predict,
        bytes: bytes,
        filename: imageFile.name,
        fieldName: 'file',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return _normalizeResponse(data);
      }

      throw Exception('Prediction API returned ${response.statusCode}');
    } catch (e) {
      debugPrint('MLService (Mobile): Prediction failed - $e');
      rethrow;
    }
  }

  /// Normalize backend response to match DiagnosisResultScreen format.
  Map<String, dynamic> _normalizeResponse(Map<String, dynamic> data) {
    final rawSteps = data['treatment_steps'];
    if (rawSteps is List) {
      data['treatment_steps'] = rawSteps.map((s) {
        if (s is Map<String, dynamic>) {
          return {
            'step': s['step'] ?? s['step_number'] ?? '',
            'step_number': s['step_number'] ?? s['step'] ?? '',
            'description': s['description'] ?? '',
          };
        }
        return s;
      }).toList();
    }

    final rawConf = (data['confidence'] as num?)?.toDouble() ?? 0.0;
    data['confidence'] = rawConf <= 1.0 ? rawConf * 100 : rawConf;
    data['is_healthy'] = data['is_healthy'] == true;

    return data;
  }

  void dispose() {}
}
