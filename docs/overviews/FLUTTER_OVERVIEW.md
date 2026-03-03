# Flutter App Documentation

## 📱 Mobile App Overview

The mobile application is built with **Flutter 3.38+** and follows a feature-based architecture. It is designed to be performant, offline-capable (future), and user-friendly for farmers.

---

## 🏗️ Architecture

We use a **Layered Feature-First Architecture** combined with **Riverpod** for state management.

### Directory Structure (`lib/`)

```
lib/
├── config/              # App-wide configuration
│   ├── routes.dart      # Navigation routes
│   └── theme.dart       # App styling (Colors, Fonts)
├── core/                # Core utilities shared across features
│   ├── api/             # API Client (Dio setup)
│   ├── services/        # Global services (Storage, ML)
│   └── utils/
│       └── app_logger.dart  # Structured logging (dart:developer)
├── features/            # Feature-based modules
│   ├── auth/            # Login, Register, OTP
│   ├── diagnosis/       # Camera, ML Prediction, Voice Input, Results
│   ├── community/       # Forum, Posts, Comments
│   ├── farm/            # Crop management, Tasks
│   ├── questions/       # Ask Expert Q&A
│   ├── market/          # Market prices with GPS location filter
│   └── encyclopedia/    # Crops, Diseases & Pests (3 tabs)
├── l10n/                # Localization ARB files (en, hi, ta, te)
├── shared/              # Reusable UI widgets
└── main.dart            # Entry point
```

---

## 📦 Key Technologies & Packages

Here are the major packages used and **why**:

### 1. State Management
*   **`flutter_riverpod`** (v2.4.9): A reactive caching and data-binding framework.
    *   *Why?* Much safer and more testable than Provider or GetX. It handles asynchronous state (like API calls) beautifully with `AsyncValue`.

### 2. Networking
*   **`dio`** (v5.4.0): A powerful HTTP client for Dart.
    *   *Why?* Supports interceptors (for JWT headers), global configuration, and file uploads better than the basic `http` package.
*   **`connectivity_plus`**: Checks for internet connection.

### 3. On-Device ML & Artificial Intelligence
*   **`tflite_flutter_plus`**: Runs TensorFlow Lite models ensuring offline capability.
    *   *Why?* Allows the app to run the disease detection model directly on the phone's CPU/GPU without needing internet (Hybrid approach).
*   **`image`**: Used for resizing and preprocessing images before sending them to the model.

### 4. Hardware Interaction
*   **`camera`** (v0.10.5): Accesses the device camera for taking crop photos.
*   **`image_picker`** (v1.1.2): Selects images from the gallery.
*   **`geolocator`** (v13.0.0): Gets the user's GPS coordinates for location-based market prices and weather data.
*   **`geocoding`**: Reverse-geocodes GPS coordinates to city/district names for market filtering.
*   **`permission_handler`** (v12.0.1): Manages camera, location, and microphone permissions.

### 5. Storage
*   **`flutter_secure_storage`** (v9.0.0): Stores sensitive data like **JWT Tokens** securely in the Keychain/Keystore.
    *   *Why?* Never store auth tokens in plain text (SharedPreferences).
*   **`shared_preferences`**: Stores simple settings (e.g., "Has user seen onboarding?").
*   **`sqflite`** (v2.3.0): Local SQLite database for offline data caching.

### 6. Accessibility & Audio
*   **`flutter_tts`** (v4.2.5) - Text-to-Speech: Reads out diagnosis results and advice to the farmer.
    *   *Why?* Vital for accessibility, especially for farmers who may prefer listening over reading complex agricultural text.
*   **`speech_to_text`** (v7.3.0): Transcribes farmer's spoken symptom descriptions on the Diagnosis screen (`en_IN` locale for Indian farming terms).

### 7. UI & UX
*   **`google_fonts`** (v6.2.1): Provides modern typography.
*   **`lottie`** (v3.1.2): Renders high-quality animations (e.g., loading screens).
*   **`rive`** (v0.13.4): Interactive animations.
*   **`animate_do`** (v4.2.0): Predefined animation widgets.
*   **`fluttertoast`**: Shows simple popup messages ("Saved successfully").
*   **`shimmer`** (v3.0.0): Loading skeleton effects.
*   **`fl_chart`** (v0.69.0): Charts for farm management analytics.
*   **`cached_network_image`**: Efficiently loads and caches network images.

---

## 🔄 App Flow

1.  **Splash Screen**: Checks if a valid Token exists in Secure Storage.
2.  **Auth**: If no token, user logs in or registers (via API).
3.  **Home**:
    *   **Diagnosis**: User takes a photo → App crops/resizes → Sends to API/Local Model → Shows Result.
    *   **Community**: Fetches posts using Riverpod Providers.
    *   **Farm**: Manage crops and tasks locally/synced.

---

## 🧪 Testing

**Framework**: Flutter Test (built-in)
**Total Tests**: 54

### Running Tests
```bash
cd frontend/flutter_app

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/core/services/api_client_test.dart

# Verbose output
flutter test --reporter expanded
```

### Test Structure
| Test File | Tests | Coverage |
|-----------|-------|----------|
| `test/unit_test.dart` | 17 | Validation, Models, Enums |
| `test/core/services/api_client_test.dart` | 37 | API endpoints, URL building |
| `test/widget_test.dart` | 0 | Placeholder for widget tests |

**Expected Output**:
```
00:02 +54: All tests passed!
```

---

## 🎨 Linting

**Tool**: Flutter Analyze (built-in static analyzer)

### Running Linter
```bash
cd frontend/flutter_app

# Check for issues
flutter analyze

# CI mode (warnings allowed)
flutter analyze --no-fatal-infos --no-fatal-warnings
```

### What It Checks
*   Type errors
*   Unused imports and variables
*   Code style (based on `flutter_lints`)
*   Unnecessary null checks

**CI Integration**: Runs on every push with warnings allowed.

---

## 🔨 Building the App

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA
```bash
flutter build ios --release
# Requires macOS and Xcode
```

### Web
```bash
flutter build web
# Output: build/web/
```

---

## 🌐 Translation & Localization

**Status**:

### Implementation

- **`flutter_localizations`** SDK package + `generate: true` in `pubspec.yaml`
- **`l10n.yaml`** config file at project root
- **ARB files** in `lib/l10n/`: `app_en.arb`, `app_hi.arb`, `app_ta.arb`, `app_te.arb` (50+ keys each)
- **Generated classes**: `lib/l10n/app_localizations.dart` (auto-generated by `flutter gen-l10n`)
- **`app.dart`**: wired with `localizationsDelegates`, `supportedLocales`, and `localeResolutionCallback`

### Supported Languages

| Code | Language | Script |
|------|----------|--------|
| `en` | English | Latin |
| `hi` | Hindi | Devanagari |
| `ta` | Tamil | Tamil |
| `te` | Telugu | Telugu |

### Using Translations in Code
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.diagnoseTitle)        // "Diagnose Crop" / "फसल का निदान करें"
Text(l10n.encyclopediaPests)    // "Pests" / "கீடங்கள்"
```

### Switching Language at Runtime
The app auto-detects device language. To switch programmatically, update `_locale` in `_CropDiagnosisAppState`.

---

## 🚀 Running the App

### Development
```bash
cd frontend/flutter_app

# Generate localization files (Required on first setup)
flutter gen-l10n

# Web
flutter run -d chrome

# Android Emulator
flutter run

# iOS Simulator (macOS only)
flutter run -d ios
```

### Environment Setup
Copy `.env.example` to `.env` in `assets/`:
```env
API_BASE_URL=http://localhost:8000
```

---

## 📚 Key Features

1.  **AI Diagnosis**: Camera → ML Model → Treatment Plan
2.  **Voice Input**: Describe symptoms by voice on the Diagnosis screen (`speech_to_text`, `en_IN` locale)
3.  **Expert Q&A**: Ask questions, rate answers
4.  **Community Forum**: Posts, comments, likes
5.  **Farm Management**: Track crops, manage tasks
6.  **Market Prices**: Real-time commodity prices with **GPS location filter** (auto-detects nearest city)
7.  **Encyclopedia**: Browse Crops, Diseases & **Pests** (3-tab UI, 8 pests seeded)
8.  **Multi-Language**: UI in English, Hindi, Tamil, Telugu
9.  **Accessibility**: TTS & STT for voice interaction

## 🪵 Logging

The app uses `AppLogger` (`lib/core/utils/app_logger.dart`) — a zero-dependency logger built on `dart:developer`:

```dart
AppLogger.info('Market data loaded', tag: 'Market');
AppLogger.error('API failed', tag: 'Market', error: e, stackTrace: st);
```

Logs appear in:
- `flutter run` terminal output
- Android Logcat (filter tag: `CropDiag`)
- Xcode Console / iOS device logs

Debug-level logs are suppressed in release builds automatically.
