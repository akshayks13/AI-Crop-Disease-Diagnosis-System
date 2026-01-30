import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';

final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(GeminiService());
});

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isListening;
  final String selectedLanguage;
  final String? errorMsg;

  ChatState({
    required this.messages,
    required this.isLoading,
    this.isListening = false,
    this.selectedLanguage = 'English',
    this.errorMsg,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isListening,
    String? selectedLanguage,
    String? errorMsg,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isListening: isListening ?? this.isListening,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      errorMsg: errorMsg,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GeminiService _geminiService;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isSpeechInitialized = false;

  final List<String> supportedLanguages = ['English', 'Hindi', 'Punjabi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Marathi', 'Bengali', 'Gujarati'];

  ChatNotifier(this._geminiService) : super(ChatState(messages: [], isLoading: false)) {
    _initSpeech();
    _initTts();
    // Add initial greeting
    state = state.copyWith(messages: [
      Message(
        text: "Hello! I'm your farming assistant. Ask me anything about crops, weather, or market prices!",
        isUser: false,
        time: DateTime.now(),
      )
    ]);
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (e) => print('Speech Error: $e'),
        onStatus: (s) => print('Speech Status: $s'),
      );
    } catch (e) {
      print('Speech Init Error: $e');
    }
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-IN"); // Default to Indian English
  }

  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
    // Adjust TTS language based on selection (basic mapping)
    switch (language) {
      case 'Hindi':
        _flutterTts.setLanguage("hi-IN");
        break;
      case 'Punjabi':
        _flutterTts.setLanguage("pa-IN");
        break;
      case 'Tamil':
        _flutterTts.setLanguage("ta-IN");
        break;
      default:
        _flutterTts.setLanguage("en-IN");
    }
  }

  Future<void> startListening() async {
    if (!_isSpeechInitialized) {
      _initSpeech(); // Try initializing again if failed
    }

    if (!_isSpeechInitialized) {
      state = state.copyWith(errorMsg: "Microphone not initialized");
      return;
    }

    if (!state.isListening) {
      try {
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              sendMessage(result.recognizedWords);
              stopListening();
            }
          },
          // localeId: _getLocaleId(state.selectedLanguage), // Optional: set locale for recognition
        );
        state = state.copyWith(isListening: true, errorMsg: null);
      } catch (e) {
        state = state.copyWith(errorMsg: "Listening failed: $e");
      }
    }
  }

  Future<void> stopListening() async {
    if (state.isListening) {
      await _speech.stop();
      state = state.copyWith(isListening: false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = Message(text: text, isUser: true, time: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      // Get response
      final responseText = await _geminiService.getAIResponse(text, language: state.selectedLanguage);

      // Add bot message
      final botMsg = Message(text: responseText, isUser: false, time: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isLoading: false,
      );

      // Speak response
      speak(responseText);

    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        messages: [
          ...state.messages, 
          Message(text: "Sorry, I encountered an error.", isUser: false, time: DateTime.now())
        ]
      );
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
