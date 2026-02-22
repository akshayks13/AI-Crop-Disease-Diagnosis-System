import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Answer screen for experts to respond to or edit answers for farmer questions
class AnswerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;
  const AnswerScreen({super.key, required this.question});

  @override
  ConsumerState<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends ConsumerState<AnswerScreen> {
  final _answerController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingDetail = true;
  String? _existingAnswerId; // non-null if expert already answered
  List<Map<String, dynamic>> _otherAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestionDetail();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionDetail() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('${ApiConfig.expertQuestions}/${widget.question['id']}');
      final data = response.data as Map<String, dynamic>;
      final answers = List<Map<String, dynamic>>.from(data['answers'] ?? []);

      // Find current expert's answer
      for (var a in answers) {
        if (a['is_mine'] == true) {
          _existingAnswerId = a['id'];
          _answerController.text = a['answer_text'] ?? '';
        } else {
          _otherAnswers.add(a);
        }
      }
    } catch (_) {
      // If detail fetch fails, just show new answer mode
    }
    if (mounted) setState(() => _isLoadingDetail = false);
  }

  bool get _isEditMode => _existingAnswerId != null;

  Future<void> _submitOrUpdate() async {
    if (_answerController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a more detailed answer (at least 10 characters)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);

      if (_isEditMode) {
        // Edit existing answer
        await api.put('${ApiConfig.expertAnswer}/$_existingAnswerId', data: {
          'answer_text': _answerController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer updated!'), backgroundColor: AppTheme.primaryGreen),
          );
          Navigator.pop(context);
        }
      } else {
        // Submit new answer
        await api.post(ApiConfig.expertAnswer, data: {
          'question_id': widget.question['id'],
          'answer_text': _answerController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer submitted!'), backgroundColor: AppTheme.primaryGreen),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Answer' : 'Answer Question')),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(widget.question['farmer_name'] ?? 'Farmer',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ]),
                        const SizedBox(height: 12),
                        Text(widget.question['question_text'] ?? '', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),

                  // Other experts' answers
                  if (_otherAnswers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Other Expert Answers', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    ..._otherAnswers.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['expert_name'] ?? 'Expert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          Text(a['answer_text'] ?? '', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )),
                  ],

                  // Your answer section
                  const SizedBox(height: 24),
                  Text(
                    _isEditMode ? 'Your Answer (edit below)' : 'Your Answer',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: _isEditMode ? 'Edit your answer...' : 'Provide detailed guidance...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitOrUpdate,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_isEditMode ? Icons.edit : Icons.send),
                      label: Text(_isSubmitting
                          ? (_isEditMode ? 'Updating...' : 'Submitting...')
                          : (_isEditMode ? 'Update Answer' : 'Submit Answer')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
