import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../constants/disease_labels.dart';
import '../api/api_config.dart';
import '../api/api_client.dart';

/// ML Service for web - uses local simulation with proper TFLite labels
/// since TFLite doesn't run natively in the browser.
class MLService {
  final Ref ref;

  MLService(this.ref);

  Future<void> initialize() async {
    print('MLService (Web): Ready — using local label simulation');
  }

  /// Run inference — on web we simulate using proper TFLite labels
  /// so that the DSS can match them correctly.
  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Try to persist via backend API for history, but use local
      // label-based prediction for the actual result
      String? persistedId;
      try {
        persistedId = await _persistViaApi(bytes, imageFile.name);
      } catch (e) {
        print('MLService (Web): API persist failed - $e');
      }

      // Use local simulation with REAL TFLite labels
      final result = _simulatePrediction(bytes);
      if (persistedId != null) {
        result['id'] = persistedId;
      }
      return result;
    } catch (e) {
      print('MLService (Web): Prediction failed - $e');
      rethrow;
    }
  }

  /// Persist diagnosis to backend (for history) — returns the diagnosis ID
  Future<String?> _persistViaApi(Uint8List bytes, String filename) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.uploadFileBytes(
        ApiConfig.predict,
        bytes: bytes,
        filename: filename,
        fieldName: 'file',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['id']?.toString();
      }
    } catch (e) {
      print('MLService (Web): Persist API error - $e');
    }
    return null;
  }

  /// Simulate prediction using REAL TFLite labels from disease_labels.dart.
  /// This ensures DSS can always match the label correctly.
  Map<String, dynamic> _simulatePrediction(Uint8List bytes) {
    final image = img.decodeImage(bytes);

    // Pick a label index based on image properties for variety
    int index = 0;
    if (image != null) {
      index = (image.width + image.height) % diseaseLabels.length;
    }

    final label = diseaseLabels[index];
    final diseaseInfo = DiseaseInfo.fromLabel(label);

    // Simulated confidence between 70-95%
    final confidence = 70.0 + (index % 26);

    String severity;
    if (diseaseInfo.isHealthy) {
      severity = 'none';
    } else if (confidence >= 80) {
      severity = 'high';
    } else if (confidence >= 50) {
      severity = 'medium';
    } else {
      severity = 'low';
    }

    return {
      'disease': diseaseInfo.disease,
      'plant': diseaseInfo.plant,
      'disease_id': label, // Real TFLite label — e.g. 'tomato_early_blight'
      'confidence': confidence,
      'severity': severity,
      'is_healthy': diseaseInfo.isHealthy,
      'treatment_steps': _getTreatmentSteps(diseaseInfo),
    };
  }

  List<Map<String, String>> _getTreatmentSteps(DiseaseInfo info) {
    if (info.isHealthy) {
      return [
        {'step_number': '1', 'description': 'Your plant appears healthy! Continue regular care.'},
        {'step_number': '2', 'description': 'Maintain proper watering and sunlight exposure.'},
        {'step_number': '3', 'description': 'Monitor regularly for any signs of disease.'},
      ];
    }

    return [
      {'step_number': '1', 'description': 'Remove affected leaves and dispose properly.'},
      {'step_number': '2', 'description': 'Apply appropriate fungicide or pesticide treatment.'},
      {'step_number': '3', 'description': 'Improve air circulation around plants.'},
      {'step_number': '4', 'description': 'Avoid overhead watering to reduce moisture on leaves.'},
      {'step_number': '5', 'description': 'Consult an expert for severe infections.'},
    ];
  }

  void dispose() {}
}
