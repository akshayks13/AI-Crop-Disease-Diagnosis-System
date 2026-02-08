// Dummy implementation for Web build to avoid tflite_flutter_plus dependency
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class MLService {
  final Ref ref;
  MLService(this.ref);

  Future<void> initialize() async {
    print('MLService (Web Dummy): initialize called - no-op');
  }

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    print('MLService (Web Dummy): predict called - returning empty');
    return {};
  }
  
  void dispose() {}
}
