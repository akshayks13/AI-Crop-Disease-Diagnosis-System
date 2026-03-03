import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'core/providers/auth_provider.dart';

class CropDiagnosisApp extends ConsumerStatefulWidget {
  const CropDiagnosisApp({super.key});

  @override
  ConsumerState<CropDiagnosisApp> createState() => _CropDiagnosisAppState();
}

class _CropDiagnosisAppState extends ConsumerState<CropDiagnosisApp> {
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Crop Diagnosis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Localizations ──────────────────────────────────────────────────────
      locale: _locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('ta'), // Tamil
        Locale('te'), // Telugu
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en');
      },
      // ──────────────────────────────────────────────────────────────────────

      initialRoute: authState.when(
        data: (user) => user != null ? AppRoutes.home : AppRoutes.login,
        loading: () => AppRoutes.splash,
        error: (_, __) => AppRoutes.login,
      ),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
