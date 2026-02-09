import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Stub ML Service (used when platform is unknown)
class MLService {
  final Ref ref;

  MLService(this.ref);

  Future<void> initialize() async {
    print('MLService (Stub): No implementation available');
  }

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    throw UnimplementedError('ML Service not available on this platform');
  }

  void dispose() {}
}
