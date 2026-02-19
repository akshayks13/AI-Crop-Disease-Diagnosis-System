// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'फसल निदान';

  @override
  String get navHome => 'होम';

  @override
  String get navDiagnose => 'निदान';

  @override
  String get navMarket => 'बाज़ार';

  @override
  String get navWeather => 'मौसम';

  @override
  String get navCommunity => 'समुदाय';

  @override
  String get navEncyclopedia => 'विश्वकोश';

  @override
  String get diagnoseTitle => 'फसल का निदान करें';

  @override
  String get diagnoseInstruction =>
      'सटीक निदान के लिए प्रभावित पौधे के हिस्से की स्पष्ट तस्वीर लें।';

  @override
  String get diagnoseTakePhoto => 'फोटो लें';

  @override
  String get diagnoseChooseGallery => 'गैलरी से चुनें';

  @override
  String get diagnoseAnalyze => 'फसल का विश्लेषण करें';

  @override
  String get diagnoseAnalyzing => 'विश्लेषण हो रहा है...';

  @override
  String get diagnoseTapToCapture => 'छवि कैप्चर करने के लिए टैप करें';

  @override
  String get diagnoseRemoveImage => 'छवि हटाएं';

  @override
  String get voiceDescribeSymptoms => 'लक्षण बताएं (वैकल्पिक)';

  @override
  String get voiceListening => 'सुन रहा है... अभी बोलें';

  @override
  String get voiceTapToDescribe => 'लक्षण बताने के लिए माइक टैप करें';

  @override
  String get voiceTapToStop => 'रोकने के लिए फिर टैप करें';

  @override
  String get voiceExample => 'उदा., \"पत्तियों पर पीले धब्बे, मुरझाना\"';

  @override
  String voiceWordsRecorded(int count) {
    return '$count शब्द रिकॉर्ड हुए';
  }

  @override
  String get encyclopediaTitle => 'फसल विश्वकोश';

  @override
  String get encyclopediaCrops => 'फसलें';

  @override
  String get encyclopediaDiseases => 'रोग';

  @override
  String get encyclopediaPests => 'कीट';

  @override
  String get encyclopediaSearchCrops => 'फसल के नाम से खोजें';

  @override
  String get encyclopediaSearchDiseases => 'रोग के नाम से खोजें';

  @override
  String get encyclopediaSearchPests => 'कीट या प्रभावित फसल से खोजें';

  @override
  String get marketTitle => 'बाज़ार भाव';

  @override
  String get weatherTitle => 'मौसम';

  @override
  String get communityTitle => 'समुदाय';

  @override
  String get buttonRetry => 'पुनः प्रयास करें';

  @override
  String get buttonCancel => 'रद्द करें';

  @override
  String get buttonSave => 'सहेजें';

  @override
  String get buttonSubmit => 'जमा करें';

  @override
  String get errorGeneric => 'कुछ गलत हुआ। कृपया पुनः प्रयास करें।';

  @override
  String get errorNoInternet => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get errorPermissionDenied => 'अनुमति अस्वीकृत';

  @override
  String get severityMild => 'हल्का';

  @override
  String get severityModerate => 'मध्यम';

  @override
  String get severitySevere => 'गंभीर';
}
