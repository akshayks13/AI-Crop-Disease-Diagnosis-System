import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../constants/disease_labels.dart';
import '../api/api_config.dart';
import '../api/api_client.dart';

/// ML Service for web - uses backend API since TFLite doesn't work on web
class MLService {
  final Ref ref;

  MLService(this.ref);

  Future<void> initialize() async {
    // No initialization needed for web - using API
    print('MLService (Web): Ready to use backend API');
  }

  /// Run inference via backend API
  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // ---------------------------------------------------------
      // PERSISTENCE & DIAGNOSIS
      // ---------------------------------------------------------
      // We call the API to:
      // 1. Persist the diagnosis in the database (History)
      // 2. Get the backend's simulated result
      try {
        return await _predictViaApi(bytes, imageFile.name);
      } catch (apiError) {
        print('MLService (Web): API failed, using local simulation - $apiError');
        // Fallback to local simulated prediction if API fails
        return _simulatePrediction(bytes);
      }
      
    } catch (e) {
      print('MLService (Web): Prediction failed - $e');
      rethrow;
    }
  }

  /// Call backend API for prediction
  Future<Map<String, dynamic>> _predictViaApi(Uint8List bytes, String filename) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Use helper method from ApiClient which handles Auth headers and Multipart
      final response = await apiClient.uploadFileBytes(
        ApiConfig.predict, // /diagnosis/predict
        bytes: bytes,
        filename: filename,
        fieldName: 'file', // Backend expects 'file'
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Transform backend response to match UI expectations
        return {
          'id': data['id'], // Persisted ID
          'disease': data['disease'],
          'plant': data['crop_type'] ?? 'Unknown Plant',
          'disease_id': data['disease'], 
          'confidence': data['confidence'],
          'severity': data['severity'],
          'is_healthy': (data['disease'] as String).toLowerCase() == 'healthy',
          'is_simulated': false,
          'treatment_steps': data['treatment_steps'] ?? [],
          'chemical_options': data['chemical_options'] ?? [],
          'organic_options': data['organic_options'] ?? [],
          'prevention': data['prevention'],
          'warnings': data['warnings'],
        };
      } else {
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      print('API Exception: $e');
      rethrow;
    }
  }

  /// Simulate prediction for web demo (when API not available)
  Map<String, dynamic> _simulatePrediction(Uint8List bytes) {
    // Decode image to get some variety in results
    final image = img.decodeImage(bytes);
    
    // Use image properties to pick a "random" disease for demo
    int index = 0;
    if (image != null) {
      // Use image dimensions to pick a label index
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
      'id': 'mock_${DateTime.now().millisecondsSinceEpoch}', // Mock ID for rating
      'disease': diseaseInfo.disease,
      'plant': diseaseInfo.plant,
      'disease_id': label,
      'confidence': confidence / 100.0,
      'severity': severity,
      'is_healthy': diseaseInfo.isHealthy,
      'is_simulated': true,
      'treatment_steps': _getTreatmentSteps(diseaseInfo),
      // Mock data for new UI sections
      'chemical_options': [
         {'name': 'Copper Fungicide', 'dosage': '2g/L', 'application_method': 'Spray', 'frequency': 'Weekly'},
         {'name': 'Mancozeb', 'dosage': '2.5g/L', 'application_method': 'Foliar Spray', 'frequency': 'Every 10 days'},
      ],
      'organic_options': [
         {'name': 'Neem Oil', 'dosage': '5ml/L', 'application_method': 'Spray', 'frequency': 'Every 5 days'},
         {'name': 'Garlic Extract', 'dosage': '10ml/L', 'application_method': 'Spray', 'frequency': 'Weekly'},
      ],
      'prevention': 'Regularly monitor your crops, ensure proper spacing for air circulation, and avoid overhead watering to reduce moisture on leaves.',
      'warnings': severity == 'high' ? 'Immediate action required! Separate infected plants.' : null,
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
