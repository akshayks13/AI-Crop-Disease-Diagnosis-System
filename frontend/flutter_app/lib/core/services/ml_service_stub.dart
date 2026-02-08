import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class MLService {
  MLService(Ref ref);

  Future<void> initialize() => throw UnimplementedError();
  Future<Map<String, dynamic>> predict(XFile imageFile) => throw UnimplementedError();
}
