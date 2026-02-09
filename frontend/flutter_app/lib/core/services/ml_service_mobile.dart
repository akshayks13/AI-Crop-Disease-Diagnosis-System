import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';

import '../constants/disease_labels.dart';

/// ML Service for on-device plant disease classification (Mobile only)
class MLService {
  final Ref ref;
  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const int _inputSize = 224;
  static const String _modelPath = 'assets/models/Disease_Classification_v2_compressed.tflite';

  MLService(this.ref);

  /// Initialize the TFLite model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isInitialized = true;
      print('MLService: Model loaded successfully');
    } catch (e) {
      print('MLService: Failed to load model - $e');
      rethrow;
    }
  }

  /// Run inference on an image file
  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final input = _preprocessImage(bytes);

      final output = List.filled(1 * diseaseLabels.length, 0.0).reshape([1, diseaseLabels.length]);

      _interpreter!.run(input, output);

      final predictions = (output[0] as List<double>);
      
      int maxIndex = 0;
      double maxScore = predictions[0];
      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxScore) {
          maxScore = predictions[i];
          maxIndex = i;
        }
      }

      final label = diseaseLabels[maxIndex];
      final diseaseInfo = DiseaseInfo.fromLabel(label);
      final confidence = (maxScore * 100).clamp(0, 100);

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
        'treatment_steps': _getTreatmentSteps(diseaseInfo),
      };
    } catch (e) {
      print('MLService: Prediction failed - $e');
      rethrow;
    }
  }

  List<List<List<List<double>>>> _preprocessImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    return input;
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

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
