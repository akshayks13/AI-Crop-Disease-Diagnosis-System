/// API Configuration Constants
class ApiConfig {
  // Base URL - change for production
 static const String baseUrl = 'https://subepithelial-shenika-unaddible.ngrok-free.dev';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verify = '/auth/verify';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  
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
  static const String expertMyAnswers = '/expert/my-answers';
  
  // Market endpoints
  static const String marketPrices = '/market/prices';
  
  // Community endpoints
  static const String communityPosts = '/community/posts';
  
  // Farm endpoints
  static const String farmCrops = '/farm/crops';
  static const String farmTasks = '/farm/tasks';
  
  // Encyclopedia endpoints
  static const String encyclopediaCrops = '/encyclopedia/crops';
  static const String encyclopediaDiseases = '/encyclopedia/diseases';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
}

