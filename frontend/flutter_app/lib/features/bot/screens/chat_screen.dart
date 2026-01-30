import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    
    // Scroll to bottom when message added
    ref.listen(chatProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        title: const Text('Farm Assistant'),
        backgroundColor: const Color(0xFF1E1E1E), // Dark app bar
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Language Selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (String language) {
              ref.read(chatProvider.notifier).setLanguage(language);
            },
            itemBuilder: (BuildContext context) {
              return ref.read(chatProvider.notifier).supportedLanguages.map((String language) {
                return PopupMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E), // Dark loading bubble
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (chatState.errorMsg != null)
             Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                chatState.errorMsg!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _buildInputArea(chatState.isListening),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryGreen : const Color(0xFF1E1E1E), // Dark bot bubble
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: Colors.white, // White text for both (since bot bubble is dark now)
                fontSize: 16,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(msg.time),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                       ref.read(chatProvider.notifier).speak(msg.text);
                    },
                    child: const Icon(Icons.volume_up, size: 14, color: Colors.white54),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isListening) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(top: 12, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark input container background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), // Slightly lighter dark for input field
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                cursorColor: AppTheme.primaryGreen,
                style: const TextStyle(color: Colors.white), // White input text
                decoration: InputDecoration(
                  hintText: isListening ? 'Listening...' : 'Type your question...',
                  hintStyle: TextStyle(color: isListening ? AppTheme.primaryGreen : Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  prefixIcon: const Icon(Icons.flash_on, color: AppTheme.accentOrange, size: 20),
                  filled: false, 
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mic Button
          GestureDetector(
            onLongPress: () {
               ref.read(chatProvider.notifier).startListening();
            },
            onLongPressUp: () {
               ref.read(chatProvider.notifier).stopListening();
            },
            onTap: () {
                if (isListening) {
                   ref.read(chatProvider.notifier).stopListening();
                } else {
                   ref.read(chatProvider.notifier).startListening();
                }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isListening ? Colors.redAccent : const Color(0xFF2C2C2C),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none, 
                color: Colors.white, 
                size: 24
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              onPressed: _sendMessage,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(_controller.text);
    _controller.clear();
  }
}
