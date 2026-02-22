import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Crop Diagnosis'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDiagnose.
  ///
  /// In en, this message translates to:
  /// **'Diagnose'**
  String get navDiagnose;

  /// No description provided for @navMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarket;

  /// No description provided for @navWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get navWeather;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navEncyclopedia.
  ///
  /// In en, this message translates to:
  /// **'Encyclopedia'**
  String get navEncyclopedia;

  /// No description provided for @diagnoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnose Crop'**
  String get diagnoseTitle;

  /// No description provided for @diagnoseInstruction.
  ///
  /// In en, this message translates to:
  /// **'Take a clear photo of the affected plant part for accurate diagnosis.'**
  String get diagnoseInstruction;

  /// No description provided for @diagnoseTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get diagnoseTakePhoto;

  /// No description provided for @diagnoseChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get diagnoseChooseGallery;

  /// No description provided for @diagnoseAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze Crop'**
  String get diagnoseAnalyze;

  /// No description provided for @diagnoseAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get diagnoseAnalyzing;

  /// No description provided for @diagnoseTapToCapture.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture or select image'**
  String get diagnoseTapToCapture;

  /// No description provided for @diagnoseRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get diagnoseRemoveImage;

  /// No description provided for @voiceDescribeSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Describe Symptoms (Optional)'**
  String get voiceDescribeSymptoms;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... speak now'**
  String get voiceListening;

  /// No description provided for @voiceTapToDescribe.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to describe symptoms'**
  String get voiceTapToDescribe;

  /// No description provided for @voiceTapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap again to stop'**
  String get voiceTapToStop;

  /// No description provided for @voiceExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"yellow spots on leaves, wilting\"'**
  String get voiceExample;

  /// No description provided for @voiceWordsRecorded.
  ///
  /// In en, this message translates to:
  /// **'{count} words recorded'**
  String voiceWordsRecorded(int count);

  /// No description provided for @encyclopediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Encyclopedia'**
  String get encyclopediaTitle;

  /// No description provided for @encyclopediaCrops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get encyclopediaCrops;

  /// No description provided for @encyclopediaDiseases.
  ///
  /// In en, this message translates to:
  /// **'Diseases'**
  String get encyclopediaDiseases;

  /// No description provided for @encyclopediaPests.
  ///
  /// In en, this message translates to:
  /// **'Pests'**
  String get encyclopediaPests;

  /// No description provided for @encyclopediaSearchCrops.
  ///
  /// In en, this message translates to:
  /// **'Search by crop name or scientific name'**
  String get encyclopediaSearchCrops;

  /// No description provided for @encyclopediaSearchDiseases.
  ///
  /// In en, this message translates to:
  /// **'Search by disease name'**
  String get encyclopediaSearchDiseases;

  /// No description provided for @encyclopediaSearchPests.
  ///
  /// In en, this message translates to:
  /// **'Search by pest name or affected crop'**
  String get encyclopediaSearchPests;

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketTitle;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @buttonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get buttonSubmit;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNoInternet;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get errorPermissionDenied;

  /// No description provided for @severityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
