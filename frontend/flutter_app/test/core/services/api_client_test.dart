// Real functional tests for ApiConfig
// Tests all endpoint constants and timeout configurations
//
// Run with: flutter test test/core/services/api_client_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/api/api_config.dart';

void main() {
  group('ApiConfig Base URL Tests', () {
    test('baseUrl should be properly formatted HTTP URL', () {
      expect(ApiConfig.baseUrl, isNotNull);
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl, startsWith('http'));
      expect(ApiConfig.baseUrl, isNot(endsWith('/')));
    });

    test('baseUrl should point to localhost in dev', () {
      expect(ApiConfig.baseUrl, contains('localhost'));
    });
  });

  group('ApiConfig Auth Endpoint Tests', () {
    test('login endpoint should be /auth/login', () {
      expect(ApiConfig.login, equals('/auth/login'));
    });

    test('register endpoint should be /auth/register', () {
      expect(ApiConfig.register, equals('/auth/register'));
    });

    test('verify endpoint should be /auth/verify', () {
      expect(ApiConfig.verify, equals('/auth/verify'));
    });

    test('refresh endpoint should be /auth/refresh', () {
      expect(ApiConfig.refresh, equals('/auth/refresh'));
    });

    test('me endpoint should be /auth/me', () {
      expect(ApiConfig.me, equals('/auth/me'));
    });

    test('updateProfile endpoint should be /auth/profile', () {
      expect(ApiConfig.updateProfile, equals('/auth/profile'));
    });

    test('forgotPassword endpoint should exist', () {
      expect(ApiConfig.forgotPassword, equals('/auth/forgot-password'));
    });

    test('resetPassword endpoint should exist', () {
      expect(ApiConfig.resetPassword, equals('/auth/reset-password'));
    });

    test('all auth endpoints should start with /auth/', () {
      final authEndpoints = [
        ApiConfig.login,
        ApiConfig.register,
        ApiConfig.verify,
        ApiConfig.refresh,
        ApiConfig.me,
        ApiConfig.updateProfile,
        ApiConfig.forgotPassword,
        ApiConfig.resetPassword,
      ];
      
      for (final endpoint in authEndpoints) {
        expect(endpoint, startsWith('/auth/'));
      }
    });
  });

  group('ApiConfig Diagnosis Endpoint Tests', () {
    test('predict endpoint should be /diagnosis/predict', () {
      expect(ApiConfig.predict, equals('/diagnosis/predict'));
    });

    test('diagnosisHistory endpoint should be /diagnosis/history', () {
      expect(ApiConfig.diagnosisHistory, equals('/diagnosis/history'));
    });

    test('diagnosisDetail endpoint should be /diagnosis', () {
      expect(ApiConfig.diagnosisDetail, equals('/diagnosis'));
    });

    test('all diagnosis endpoints should start with /diagnosis', () {
      final diagnosisEndpoints = [
        ApiConfig.predict,
        ApiConfig.diagnosisHistory,
        ApiConfig.diagnosisDetail,
      ];
      
      for (final endpoint in diagnosisEndpoints) {
        expect(endpoint, startsWith('/diagnosis'));
      }
    });
  });

  group('ApiConfig Expert Endpoint Tests', () {
    test('expertStatus endpoint should exist', () {
      expect(ApiConfig.expertStatus, equals('/expert/status'));
    });

    test('expertProfile endpoint should exist', () {
      expect(ApiConfig.expertProfile, equals('/expert/profile'));
    });

    test('expertQuestions endpoint should exist', () {
      expect(ApiConfig.expertQuestions, equals('/expert/questions'));
    });

    test('expertAnswer endpoint should exist', () {
      expect(ApiConfig.expertAnswer, equals('/expert/answer'));
    });

    test('expertStats endpoint should exist', () {
      expect(ApiConfig.expertStats, equals('/expert/stats'));
    });

    test('expertMyAnswers endpoint should exist', () {
      expect(ApiConfig.expertMyAnswers, equals('/expert/my-answers'));
    });

    test('all expert endpoints should start with /expert/', () {
      final expertEndpoints = [
        ApiConfig.expertStatus,
        ApiConfig.expertProfile,
        ApiConfig.expertQuestions,
        ApiConfig.expertAnswer,
        ApiConfig.expertStats,
        ApiConfig.expertMyAnswers,
      ];
      
      for (final endpoint in expertEndpoints) {
        expect(endpoint, startsWith('/expert/'));
      }
    });
  });

  group('ApiConfig Other Endpoint Tests', () {
    test('marketPrices endpoint should exist', () {
      expect(ApiConfig.marketPrices, equals('/market/prices'));
    });

    test('communityPosts endpoint should exist', () {
      expect(ApiConfig.communityPosts, equals('/community/posts'));
    });

    test('farmCrops endpoint should exist', () {
      expect(ApiConfig.farmCrops, equals('/farm/crops'));
    });

    test('farmTasks endpoint should exist', () {
      expect(ApiConfig.farmTasks, equals('/farm/tasks'));
    });

    test('encyclopediaCrops endpoint should exist', () {
      expect(ApiConfig.encyclopediaCrops, equals('/encyclopedia/crops'));
    });

    test('encyclopediaDiseases endpoint should exist', () {
      expect(ApiConfig.encyclopediaDiseases, equals('/encyclopedia/diseases'));
    });

    test('questions endpoint should exist', () {
      expect(ApiConfig.questions, equals('/questions'));
    });
  });

  group('ApiConfig Timeout Tests', () {
    test('connectTimeout should be 30 seconds', () {
      expect(ApiConfig.connectTimeout, equals(const Duration(seconds: 30)));
    });

    test('receiveTimeout should be 60 seconds', () {
      expect(ApiConfig.receiveTimeout, equals(const Duration(seconds: 60)));
    });

    test('uploadTimeout should be 120 seconds', () {
      expect(ApiConfig.uploadTimeout, equals(const Duration(seconds: 120)));
    });

    test('connectTimeout should be less than receiveTimeout', () {
      expect(
        ApiConfig.connectTimeout.inSeconds,
        lessThan(ApiConfig.receiveTimeout.inSeconds),
      );
    });

    test('receiveTimeout should be less than uploadTimeout', () {
      expect(
        ApiConfig.receiveTimeout.inSeconds,
        lessThan(ApiConfig.uploadTimeout.inSeconds),
      );
    });
  });

  group('ApiConfig URL Building Tests', () {
    test('should build full login URL correctly', () {
      final fullUrl = '${ApiConfig.baseUrl}${ApiConfig.login}';
      expect(fullUrl, equals('http://localhost:8000/auth/login'));
    });

    test('should build full diagnosis predict URL correctly', () {
      final fullUrl = '${ApiConfig.baseUrl}${ApiConfig.predict}';
      expect(fullUrl, equals('http://localhost:8000/diagnosis/predict'));
    });

    test('should build diagnosis detail URL with ID correctly', () {
      const diagnosisId = '123-456-789';
      final fullUrl = '${ApiConfig.baseUrl}${ApiConfig.diagnosisDetail}/$diagnosisId';
      expect(fullUrl, equals('http://localhost:8000/diagnosis/123-456-789'));
    });
  });
}
