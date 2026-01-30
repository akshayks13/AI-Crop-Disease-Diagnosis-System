import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';

final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(GeminiService());
});

class ChatState {
  final List<Message> messages;
  final bool isLoading;

  ChatState({required this.messages, required this.isLoading});

  ChatState copyWith({List<Message>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GeminiService _geminiService;

  ChatNotifier(this._geminiService) : super(ChatState(messages: [], isLoading: false)) {
    // Add initial greeting
    state = state.copyWith(messages: [
      Message(
        text: "Hello! I'm your farming assistant. Ask me anything about crops, weather, or market prices!",
        isUser: false,
        time: DateTime.now(),
      )
    ]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = Message(text: text, isUser: true, time: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    // Get response
    final responseText = await _geminiService.getAIResponse(text);

    // Add bot message
    final botMsg = Message(text: responseText, isUser: false, time: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, botMsg],
      isLoading: false,
    );
  }
}
