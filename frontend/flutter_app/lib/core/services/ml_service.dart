import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ml_service_stub.dart'
    if (dart.library.io) 'ml_service_mobile.dart'
    if (dart.library.html) 'ml_service_web.dart';

final mlServiceProvider = Provider<MLService>((ref) => MLService(ref));
