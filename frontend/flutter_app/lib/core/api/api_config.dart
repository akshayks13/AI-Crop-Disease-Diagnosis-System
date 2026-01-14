/// API Configuration Constants
class ApiConfig {
  // Base URL - change for production
  static const String baseUrl = 'http://localhost:8000';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  
  // Diagnosis endpoints
  static const String predict = '/diagnosis/predict';
  static const String diagnosisHistory = '/diagnosis/history';
  static const String diagnosisDetail = '/diagnosis'; // + /{id}
  
  // Question endpoints
  static const String questions = '/questions';
  static const String questionDetail = '/questions'; // + /{id}
  
  // Expert endpoints
  static const String expertStatus = '/expert/status';
  static const String expertProfile = '/expert/profile';
  static const String expertQuestions = '/expert/questions';
  static const String expertAnswer = '/expert/answer';
  static const String expertStats = '/expert/stats';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
