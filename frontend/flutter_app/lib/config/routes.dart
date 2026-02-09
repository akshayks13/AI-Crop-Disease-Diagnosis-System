import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/diagnosis/screens/diagnosis_screen.dart';
import '../features/diagnosis/screens/diagnosis_result_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/expert/screens/expert_dashboard_screen.dart';
import '../features/expert/screens/questions_screen.dart';
import '../features/expert/screens/answer_screen.dart';
import '../features/expert/screens/expert_stats_screen.dart';
import '../features/expert/screens/answered_questions_screen.dart';
import '../features/expert/screens/answer_detail_screen.dart';
import '../features/expert/screens/knowledge_base_screen.dart';
import '../features/expert/screens/trending_diseases_screen.dart';
import '../features/expert/screens/expert_community_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/questions/screens/ask_expert_screen.dart';
import '../features/questions/screens/my_questions_screen.dart';
import '../features/weather/screens/weather_screen.dart';
import '../features/market/screens/market_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/encyclopedia/screens/encyclopedia_screen.dart';
import '../features/farm/screens/farm_screen.dart';
import '../features/bot/screens/chat_screen.dart';

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

  // New Features routes
  static const String weather = '/weather';
  static const String market = '/market';
  static const String community = '/community';
  static const String encyclopedia = '/encyclopedia';
  static const String farm = '/farm';
  static const String chat = '/chat';
  
  // Expert routes
  static const String expertDashboard = '/expert/dashboard';
  static const String expertQuestions = '/expert/questions';
  static const String expertAnswer = '/expert/answer';
  static const String expertStats = '/expert/stats';
  static const String expertMyAnswers = '/expert/my-answers';
  static const String expertAnswerDetail = '/expert/answer-detail';
  static const String expertKnowledgeBase = '/expert/knowledge-base';
  static const String expertTrending = '/expert/trending';
  static const String expertCommunity = '/expert/community';
  
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
        if (settings.arguments is! Map<String, dynamic>) {
          return _slideRoute(const DiagnosisScreen(), settings);
        }
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(DiagnosisResultScreen(result: args), settings);
      case history:
        return _slideRoute(const HistoryScreen(), settings);
      
      // Questions
      case askExpert:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(AskExpertScreen(
          diagnosisId: args?['id'], 
          diagnosisInfo: args,
        ), settings);
      case myQuestions:
        return _slideRoute(const MyQuestionsScreen(), settings);
      
      // New Features
      case weather:
        return _slideRoute(const WeatherScreen(), settings);
      case market:
        return _slideRoute(const MarketScreen(), settings);
      case community:
        return _slideRoute(const CommunityScreen(), settings);
      case encyclopedia:
        return _slideRoute(const EncyclopediaScreen(), settings);
      case farm:
        return _slideRoute(const FarmScreen(), settings);
      case chat:
        return _slideRoute(const ChatScreen(), settings);
      
      // Expert
      case expertDashboard:
        return _fadeRoute(const ExpertDashboardScreen(), settings);
      case expertQuestions:
        return _slideRoute(const QuestionsScreen(), settings);
      case expertAnswer:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(AnswerScreen(question: args), settings);
      case expertStats:
        return _slideRoute(const ExpertStatsScreen(), settings);
      case expertMyAnswers:
        return _slideRoute(const AnsweredQuestionsScreen(), settings);
      case expertAnswerDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _slideRoute(AnswerDetailScreen(answerData: args), settings);
      case expertKnowledgeBase:
        return _slideRoute(const KnowledgeBaseScreen(), settings);
      case expertTrending:
        return _slideRoute(const TrendingDiseasesScreen(), settings);
      case expertCommunity:
        return _slideRoute(const ExpertCommunityScreen(), settings);
      
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
