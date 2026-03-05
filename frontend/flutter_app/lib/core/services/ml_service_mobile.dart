import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_config.dart';
import '../api/api_client.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
/// ML Service for mobile — uses backend API for disease classification.
///
/// The TFLite model uses FlexPad (a TF Select op) which requires the
/// Flex delegate. Due to incompatibilities between tflite_flutter's
/// FFI-based initialization and the select-tf-ops AAR in Android, we use
/// the same backend API approach as the web version. This guarantees
/// correct results using the full TFLite model on the server.
class MLService {
  final Ref ref;

  MLService(this.ref);



late tfl.Interpreter interpreter;

Future<void> loadModel() async {
  try {
    final options = tfl.InterpreterOptions();
    // options.addDelegate(tfl.FlexDelegate()); // If supported by your plugin version
    interpreter = await tfl.Interpreter.fromAsset(
      'assets/Disease_Classification_v2_compressed.tflite', 
      options: options
    );
  } catch (e) {
    print('Load failed: $e');
  }
}


  /// Upload image to backend API for disease prediction
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
      print('MLService (Mobile): Prediction failed — $e');
      rethrow;
    }
  }

  /// Normalize backend response to match the format consumed by
  /// DiagnosisResultScreen. The backend may return slightly different
  /// keys depending on version, so we normalize defensively.
  Map<String, dynamic> _normalizeResponse(Map<String, dynamic> data) {
    // Normalize treatment steps — backend returns `step_number`, result
    // screen reads `description` from each map element directly.
    final rawSteps = data['treatment_steps'];
    if (rawSteps is List) {
      data['treatment_steps'] = rawSteps.map((s) {
        if (s is Map<String, dynamic>) {
          return {
            // Keep both keys for forward compatibility
            'step': s['step'] ?? s['step_number'] ?? '',
            'step_number': s['step_number'] ?? s['step'] ?? '',
            'description': s['description'] ?? '',
          };
        }
        return s;
      }).toList();
    }

    // Ensure confidence is always a percentage (0–100), not fraction (0–1)
    final rawConf = (data['confidence'] as num?)?.toDouble() ?? 0.0;
    data['confidence'] = rawConf <= 1.0 ? rawConf * 100 : rawConf;

    // Ensure is_healthy is a bool
    data['is_healthy'] = data['is_healthy'] == true;

    return data;
  }

  void dispose() {}
}
