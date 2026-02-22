// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'పంట నిర్ధారణ';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navDiagnose => 'నిర్ధారణ';

  @override
  String get navMarket => 'మార్కెట్';

  @override
  String get navWeather => 'వాతావరణం';

  @override
  String get navCommunity => 'సమాజం';

  @override
  String get navEncyclopedia => 'విజ్ఞాన సర్వస్వం';

  @override
  String get diagnoseTitle => 'పంటను నిర్ధారించండి';

  @override
  String get diagnoseInstruction =>
      'ఖచ్చితమైన నిర్ధారణ కోసం ప్రభావిత మొక్క భాగం యొక్క స్పష్టమైన ఫోటో తీయండి.';

  @override
  String get diagnoseTakePhoto => 'ఫోటో తీయండి';

  @override
  String get diagnoseChooseGallery => 'గ్యాలరీ నుండి ఎంచుకోండి';

  @override
  String get diagnoseAnalyze => 'పంటను విశ్లేషించండి';

  @override
  String get diagnoseAnalyzing => 'విశ్లేషిస్తోంది...';

  @override
  String get diagnoseTapToCapture => 'చిత్రం తీయడానికి నొక్కండి';

  @override
  String get diagnoseRemoveImage => 'చిత్రాన్ని తొలగించండి';

  @override
  String get voiceDescribeSymptoms => 'లక్షణాలు వివరించండి (ఐచ్ఛికం)';

  @override
  String get voiceListening => 'వింటోంది... ఇప్పుడు మాట్లాడండి';

  @override
  String get voiceTapToDescribe => 'లక్షణాలు వివరించడానికి మైక్ నొక్కండి';

  @override
  String get voiceTapToStop => 'ఆపడానికి మళ్ళీ నొక్కండి';

  @override
  String get voiceExample => 'ఉదా., \"ఆకులపై పసుపు మచ్చలు, వాడిపోవడం\"';

  @override
  String voiceWordsRecorded(int count) {
    return '$count పదాలు రికార్డ్ అయ్యాయి';
  }

  @override
  String get encyclopediaTitle => 'పంట విజ్ఞాన సర్వస్వం';

  @override
  String get encyclopediaCrops => 'పంటలు';

  @override
  String get encyclopediaDiseases => 'వ్యాధులు';

  @override
  String get encyclopediaPests => 'తెగుళ్ళు';

  @override
  String get encyclopediaSearchCrops => 'పంట పేరు ద్వారా వెతకండి';

  @override
  String get encyclopediaSearchDiseases => 'వ్యాధి పేరు ద్వారా వెతకండి';

  @override
  String get encyclopediaSearchPests =>
      'తెగులు లేదా ప్రభావిత పంట ద్వారా వెతకండి';

  @override
  String get marketTitle => 'మార్కెట్ ధరలు';

  @override
  String get weatherTitle => 'వాతావరణం';

  @override
  String get communityTitle => 'సమాజం';

  @override
  String get buttonRetry => 'మళ్ళీ ప్రయత్నించండి';

  @override
  String get buttonCancel => 'రద్దు చేయండి';

  @override
  String get buttonSave => 'సేవ్ చేయండి';

  @override
  String get buttonSubmit => 'సమర్పించండి';

  @override
  String get errorGeneric => 'ఏదో తప్పు జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get errorNoInternet => 'ఇంటర్నెట్ కనెక్షన్ లేదు';

  @override
  String get errorPermissionDenied => 'అనుమతి నిరాకరించబడింది';

  @override
  String get severityMild => 'తేలికపాటి';

  @override
  String get severityModerate => 'మధ్యస్థ';

  @override
  String get severitySevere => 'తీవ్రమైన';
}
