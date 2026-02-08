import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class MLService {
  final Ref ref;
  MLService(this.ref);

  Future<void> initialize() async {
    // No initialization needed for API
  }

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    final apiClient = ref.read(apiClientProvider);
    final bytes = await imageFile.readAsBytes();
    
    final response = await apiClient.uploadFileBytes(
        ApiConfig.predict,
        bytes: bytes,
        filename: imageFile.name,
        fieldName: 'file',
        // Note: crop_type is handled by caller merging logic or we could pass it here
        // But for now keeping signature simple matching mobile
        fields: {}, 
    );
    
    return response.data as Map<String, dynamic>;
  }
}
