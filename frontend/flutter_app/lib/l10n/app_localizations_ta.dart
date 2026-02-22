// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'பயிர் நோயறிதல்';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navDiagnose => 'நோயறிதல்';

  @override
  String get navMarket => 'சந்தை';

  @override
  String get navWeather => 'வானிலை';

  @override
  String get navCommunity => 'சமூகம்';

  @override
  String get navEncyclopedia => 'கலைக்களஞ்சியம்';

  @override
  String get diagnoseTitle => 'பயிரை நோயறி';

  @override
  String get diagnoseInstruction =>
      'துல்லியமான நோயறிதலுக்கு பாதிக்கப்பட்ட தாவர பகுதியின் தெளிவான புகைப்படம் எடுக்கவும்.';

  @override
  String get diagnoseTakePhoto => 'புகைப்படம் எடு';

  @override
  String get diagnoseChooseGallery => 'கேலரியிலிருந்து தேர்வு செய்';

  @override
  String get diagnoseAnalyze => 'பயிரை பகுப்பாய்வு செய்';

  @override
  String get diagnoseAnalyzing => 'பகுப்பாய்வு செய்கிறது...';

  @override
  String get diagnoseTapToCapture => 'படம் எடுக்க தட்டவும்';

  @override
  String get diagnoseRemoveImage => 'படத்தை அகற்று';

  @override
  String get voiceDescribeSymptoms => 'அறிகுறிகளை விவரிக்கவும் (விருப்பமானது)';

  @override
  String get voiceListening => 'கேட்கிறது... இப்போது பேசுங்கள்';

  @override
  String get voiceTapToDescribe => 'அறிகுறிகளை விவரிக்க மைக்கை தட்டவும்';

  @override
  String get voiceTapToStop => 'நிறுத்த மீண்டும் தட்டவும்';

  @override
  String get voiceExample => 'எ.கா., \"இலைகளில் மஞ்சள் புள்ளிகள், வாடுதல்\"';

  @override
  String voiceWordsRecorded(int count) {
    return '$count வார்த்தைகள் பதிவாயின';
  }

  @override
  String get encyclopediaTitle => 'பயிர் கலைக்களஞ்சியம்';

  @override
  String get encyclopediaCrops => 'பயிர்கள்';

  @override
  String get encyclopediaDiseases => 'நோய்கள்';

  @override
  String get encyclopediaPests => 'பூச்சிகள்';

  @override
  String get encyclopediaSearchCrops => 'பயிர் பெயரால் தேடவும்';

  @override
  String get encyclopediaSearchDiseases => 'நோய் பெயரால் தேடவும்';

  @override
  String get encyclopediaSearchPests =>
      'பூச்சி அல்லது பாதிக்கப்பட்ட பயிரால் தேடவும்';

  @override
  String get marketTitle => 'சந்தை விலைகள்';

  @override
  String get weatherTitle => 'வானிலை';

  @override
  String get communityTitle => 'சமூகம்';

  @override
  String get buttonRetry => 'மீண்டும் முயற்சி';

  @override
  String get buttonCancel => 'ரத்து செய்';

  @override
  String get buttonSave => 'சேமி';

  @override
  String get buttonSubmit => 'சமர்ப்பி';

  @override
  String get errorGeneric => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorNoInternet => 'இணைய இணைப்பு இல்லை';

  @override
  String get errorPermissionDenied => 'அனுமதி மறுக்கப்பட்டது';

  @override
  String get severityMild => 'லேசான';

  @override
  String get severityModerate => 'மிதமான';

  @override
  String get severitySevere => 'கடுமையான';
}
