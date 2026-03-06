import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// My Questions screen showing farmer's submitted questions and answers
class MyQuestionsScreen extends ConsumerStatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  ConsumerState<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends ConsumerState<MyQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(ApiConfig.questions);
      setState(() {
        _questions = List<Map<String, dynamic>>.from(response.data['questions'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Questions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.question_answer, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No questions yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) => _QuestionCard(
                      question: _questions[index],
                      onRefresh: _loadQuestions,
                    ),
                  ),
                ),
    );
  }
}

class _QuestionCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;
  final Future<void> Function() onRefresh;
  const _QuestionCard({required this.question, required this.onRefresh});

  @override
  ConsumerState<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<_QuestionCard> {
  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.baseUrl}$path';
  }

  final Map<String, int> _ratings = {}; // answerId -> rating
  final Set<String> _submitting = {}; // answerIds being submitted

  @override
  void initState() {
    super.initState();
    _initializeRatings();
  }

  void _initializeRatings() {
    final answers = widget.question['answers'] as List? ?? [];
    for (var a in answers) {
      if (a['rating'] != null && a['rating'] is int) {
        _ratings[a['id'].toString()] = a['rating'];
      }
    }
  }

  Future<void> _submitRating(String answerId, int rating) async {
    if (_submitting.contains(answerId)) return;

    setState(() {
      _submitting.add(answerId);
      _ratings[answerId] = rating;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final questionId = widget.question['id'];
      
      await apiClient.post(
        '/questions/$questionId/rate',
        queryParameters: {'answer_id': answerId, 'rating': rating},
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
        setState(() => _ratings.remove(answerId)); // Revert visual
      }
    } finally {
      if (mounted) {
        setState(() => _submitting.remove(answerId));
      }
    }
  }

  bool _isUpdatingStatus = false;

  Future<void> _updateStatus(String action) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final questionId = widget.question['id'];
      await apiClient.put('/questions/$questionId/$action');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question closed!'),
            backgroundColor: Colors.green,
          ),
        );
        await widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final status = question['status'] ?? 'OPEN';
    final isAnswered = status == 'ANSWERED';
    final isClosed = status == 'CLOSED';
    final answers = question['answers'] as List? ?? [];
    final mediaPath = question['media_path'] as String?;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed
                        ? Colors.grey.withValues(alpha: 0.2)
                        : isAnswered 
                            ? AppTheme.primaryGreen.withValues(alpha: 0.2) 
                            : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status, 
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: isClosed ? Colors.grey : isAnswered ? AppTheme.primaryGreen : Colors.orange
                    )
                  ),
                ),
                const Spacer(),
                if (answers.isNotEmpty) 
                  Text(
                    '${answers.length} answer(s)', 
                    style: theme.textTheme.bodySmall
                  ),
              ],
            ),
            // Display attached image if available
            if (mediaPath != null && mediaPath.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _resolveImageUrl(mediaPath),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: theme.disabledColor.withValues(alpha: 0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: theme.disabledColor.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(Icons.broken_image, size: 40, color: theme.disabledColor),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              question['question_text'] ?? '', 
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)
            ),
            if (answers.isNotEmpty) ...[
              const Divider(height: 24),
              ...answers.map<Widget>((a) {
                final answerId = a['id'].toString();
                final currentRating = _ratings[answerId] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Use a darker grey in dark mode, light grey in light mode
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expert: ${a['expert_name'] ?? 'Expert'}', 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: colorScheme.primary // Adapts to theme (Primary Green / Light Green)
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a['answer_text'] ?? '',
                        style: theme.textTheme.bodyMedium, // Ensures readable text color
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Rate:', 
                            style: theme.textTheme.bodySmall
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            return InkWell(
                              onTap: () => _submitRating(answerId, star),
                              child: Icon(
                                star <= currentRating ? Icons.star : Icons.star_border,
                                size: 18,
                                color: Colors.amber,
                              ),
                            );
                          }),
                          if (_submitting.contains(answerId))
                             const Padding(
                               padding: EdgeInsets.only(left: 8), 
                               child: SizedBox(
                                 width: 12, 
                                 height: 12, 
                                 child: CircularProgressIndicator(strokeWidth: 2)
                               )
                             ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ],
            if (!isClosed) ...[
              const SizedBox(height: 12),
              if (_isUpdatingStatus)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ))
              else
                OutlinedButton.icon(
                  onPressed: () => _updateStatus('close'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Close Question'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
