import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'core/providers/auth_provider.dart';

class CropDiagnosisApp extends ConsumerWidget {
  const CropDiagnosisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp(
      title: 'Crop Diagnosis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: authState.when(
        data: (user) => user != null ? AppRoutes.home : AppRoutes.login,
        loading: () => AppRoutes.splash,
        error: (_, __) => AppRoutes.login,
      ),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
