import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/diagnosis/presentation/screens/diagnosis_screen.dart';
import '../features/diagnosis/presentation/screens/diagnosis_result_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/expert/presentation/screens/expert_dashboard_screen.dart';
import '../features/expert/presentation/screens/questions_screen.dart';
import '../features/expert/presentation/screens/answer_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/questions/presentation/screens/ask_expert_screen.dart';
import '../features/questions/presentation/screens/my_questions_screen.dart';

class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  
  // Main routes
  static const String home = '/home';
  static const String profile = '/profile';
  
  // Diagnosis routes
  static const String diagnosis = '/diagnosis';
  static const String diagnosisResult = '/diagnosis/result';
  static const String history = '/history';
  
  // Question routes
  static const String askExpert = '/ask-expert';
  static const String myQuestions = '/my-questions';
  
  // Expert routes
  static const String expertDashboard = '/expert/dashboard';
  static const String expertQuestions = '/expert/questions';
  static const String expertAnswer = '/expert/answer';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case login:
        return _slideRoute(const LoginScreen(), settings);
      case register:
        return _slideRoute(const RegisterScreen(), settings);
      case otp:
        final email = settings.arguments as String;
        return _slideRoute(OtpScreen(email: email), settings);
      case forgotPassword:
        return _slideRoute(const ForgotPasswordScreen(), settings);
      case resetPassword:
        final email = settings.arguments as String;
        return _slideRoute(ResetPasswordScreen(email: email), settings);
      
      // Main
      case home:
        return _fadeRoute(const HomeScreen(), settings);
      case profile:
        return _slideRoute(const ProfileScreen(), settings);
      
      // Diagnosis
      case diagnosis:
        return _slideRoute(const DiagnosisScreen(), settings);
      case diagnosisResult:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(DiagnosisResultScreen(result: args), settings);
      case history:
        return _slideRoute(const HistoryScreen(), settings);
      
      // Questions
      case askExpert:
        return _slideRoute(const AskExpertScreen(), settings);
      case myQuestions:
        return _slideRoute(const MyQuestionsScreen(), settings);
      
      // Expert
      case expertDashboard:
        return _fadeRoute(const ExpertDashboardScreen(), settings);
      case expertQuestions:
        return _slideRoute(const QuestionsScreen(), settings);
      case expertAnswer:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(AnswerScreen(question: args), settings);
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  static Route<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  static Route<dynamic> _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
