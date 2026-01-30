import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Sends a prompt to the Gemini API and returns the generated text.
  /// [language]: The target language for the response (default: 'English').
  Future<String> getAIResponse(String prompt, {String language = 'English'}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "Error: GEMINI_API_KEY is not set in .env";
    }

    final uri = Uri.parse("$_baseUrl?key=$apiKey");

    // Construct the prompt with language instruction
    final effectivePrompt = "You are a helpful farm assistant. Please reply in $language. "
        "Keep the language simple and easy to understand for a farmer.\n\n"
        "User: $prompt";

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": effectivePrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? "No response text.";
          }
        }
        return "No response from Gemini.";
      } else {
        return "Error: ${response.statusCode} - ${response.reasonPhrase}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }

  /// Refines the raw output from the ML model into a user-friendly diagnosis.
  /// [rawDiseaseName]: The label predicted by the ML model (e.g., "Tomato___Target_Spot").
  /// [confidence]: The probability score (0.0 to 1.0).
  Future<String> explainDiseaseDiagnosis(String rawDiseaseName, double confidence, {String language = 'English'}) async {
    final prompt = "A crop disease detection model identified '$rawDiseaseName' with ${(confidence * 100).toStringAsFixed(1)}% confidence. "
        "Please explain what this disease is, its symptoms, and provide 3 practical treatment steps for a farmer. "
        "Keep the language simple and encouraging.";
    
    return await getAIResponse(prompt, language: language);
  }
}
