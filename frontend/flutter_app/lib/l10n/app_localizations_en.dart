// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Crop Diagnosis';

  @override
  String get navHome => 'Home';

  @override
  String get navDiagnose => 'Diagnose';

  @override
  String get navMarket => 'Market';

  @override
  String get navWeather => 'Weather';

  @override
  String get navCommunity => 'Community';

  @override
  String get navEncyclopedia => 'Encyclopedia';

  @override
  String get diagnoseTitle => 'Diagnose Crop';

  @override
  String get diagnoseInstruction =>
      'Take a clear photo of the affected plant part for accurate diagnosis.';

  @override
  String get diagnoseTakePhoto => 'Take Photo';

  @override
  String get diagnoseChooseGallery => 'Choose from Gallery';

  @override
  String get diagnoseAnalyze => 'Analyze Crop';

  @override
  String get diagnoseAnalyzing => 'Analyzing...';

  @override
  String get diagnoseTapToCapture => 'Tap to capture or select image';

  @override
  String get diagnoseRemoveImage => 'Remove Image';

  @override
  String get voiceDescribeSymptoms => 'Describe Symptoms (Optional)';

  @override
  String get voiceListening => 'Listening... speak now';

  @override
  String get voiceTapToDescribe => 'Tap mic to describe symptoms';

  @override
  String get voiceTapToStop => 'Tap again to stop';

  @override
  String get voiceExample => 'e.g., \"yellow spots on leaves, wilting\"';

  @override
  String voiceWordsRecorded(int count) {
    return '$count words recorded';
  }

  @override
  String get encyclopediaTitle => 'Crop Encyclopedia';

  @override
  String get encyclopediaCrops => 'Crops';

  @override
  String get encyclopediaDiseases => 'Diseases';

  @override
  String get encyclopediaPests => 'Pests';

  @override
  String get encyclopediaSearchCrops =>
      'Search by crop name or scientific name';

  @override
  String get encyclopediaSearchDiseases => 'Search by disease name';

  @override
  String get encyclopediaSearchPests => 'Search by pest name or affected crop';

  @override
  String get marketTitle => 'Market Prices';

  @override
  String get weatherTitle => 'Weather';

  @override
  String get communityTitle => 'Community';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonSubmit => 'Submit';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet => 'No internet connection';

  @override
  String get errorPermissionDenied => 'Permission denied';

  @override
  String get severityMild => 'Mild';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';
}
