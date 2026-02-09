import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../constants/disease_labels.dart';
import '../api/api_config.dart';

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
      
      // Try backend API first
      try {
        return await _predictViaApi(bytes, imageFile.name);
      } catch (apiError) {
        print('MLService (Web): API failed, using local simulation - $apiError');
        // Fallback to simulated prediction for demo
        return _simulatePrediction(bytes);
      }
    } catch (e) {
      print('MLService (Web): Prediction failed - $e');
      rethrow;
    }
  }

  /// Call backend API for prediction
  Future<Map<String, dynamic>> _predictViaApi(Uint8List bytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ml/predict');
    
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
    ));

    final response = await request.send();
    
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return json.decode(responseBody);
    } else {
      throw Exception('API returned ${response.statusCode}');
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
      'disease': diseaseInfo.disease,
      'plant': diseaseInfo.plant,
      'disease_id': label,
      'confidence': confidence,
      'severity': severity,
      'is_healthy': diseaseInfo.isHealthy,
      'is_simulated': true,  // Flag to show it's demo mode
      'treatment_steps': _getTreatmentSteps(diseaseInfo),
    };
  }

  List<Map<String, String>> _getTreatmentSteps(DiseaseInfo info) {
    if (info.isHealthy) {
      return [
        {'step': '1', 'description': 'Your plant appears healthy! Continue regular care.'},
        {'step': '2', 'description': 'Maintain proper watering and sunlight exposure.'},
        {'step': '3', 'description': 'Monitor regularly for any signs of disease.'},
      ];
    }

    return [
      {'step': '1', 'description': 'Remove affected leaves and dispose properly.'},
      {'step': '2', 'description': 'Apply appropriate fungicide or pesticide treatment.'},
      {'step': '3', 'description': 'Improve air circulation around plants.'},
      {'step': '4', 'description': 'Avoid overhead watering to reduce moisture on leaves.'},
      {'step': '5', 'description': 'Consult an expert for severe infections.'},
    ];
  }

  void dispose() {}
}
