import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/api/api_config.dart';

/// Detail screen for a question previously answered by the expert
class AnswerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> answerData;

  const AnswerDetailScreen({
    super.key,
    required this.answerData,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data
    final String farmerName = answerData['farmer_name'] ?? 'Farmer';
    final String questionText = answerData['question_text'] ?? '';
    final String answerText = answerData['answer_text'] ?? '';
    final String? mediaPath = answerData['media_path'];
    final int? rating = answerData['rating'];
    final String dateStr = _formatDate(answerData['answered_at']);
    final String timeStr = _formatTime(answerData['answered_at']);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Answer Details'),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header (if exists)
            if (mediaPath != null)
              GestureDetector(
                onTap: () => _showFullScreenImage(context, '${ApiConfig.baseUrl}$mediaPath'),
                child: Stack(
                  children: [
                    Image.network(
                      '${ApiConfig.baseUrl}$mediaPath',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(Icons.broken_image, size: 50, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('View Full', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farmer Profile
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          farmerName[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(farmerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onBackground)),
                          Text('$dateStr at $timeStr', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Question
                  Text('Question', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    questionText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onBackground, height: 1.3),
                  ),
                  
                  const SizedBox(height: 32),

                  // Answer Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: theme.shadowColor.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            answerText,
                            style: TextStyle(fontSize: 16, height: 1.5, color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Rating Section
                  if (rating != null) ...[
                    Center(
                      child: Column(
                        children: [
                          Text('Farmer Feedback', style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 36,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
  
  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
