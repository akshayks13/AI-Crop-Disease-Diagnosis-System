import 'package:flutter_riverpod/flutter_riverpod.dart';

// Conditional import: uses mobile TFLite on native, web API on browser
import 'ml_service_stub.dart'
    if (dart.library.io) 'ml_service_mobile.dart'
    if (dart.library.html) 'ml_service_web.dart';

/// Provider for MLService - automatically picks correct implementation
final mlServiceProvider = Provider<MLService>((ref) => MLService(ref));
