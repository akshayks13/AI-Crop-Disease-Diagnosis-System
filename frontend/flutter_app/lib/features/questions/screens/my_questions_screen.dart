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
                    itemBuilder: (context, index) => _QuestionCard(question: _questions[index]),
                  ),
                ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final status = question['status'] ?? 'OPEN';
    final isResolved = status == 'RESOLVED';
    final answers = question['answers'] as List? ?? [];
    final mediaPath = question['media_path'] as String?;

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
                    color: isResolved ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isResolved ? AppTheme.primaryGreen : Colors.orange)),
                ),
                const Spacer(),
                if (answers.isNotEmpty) Text('${answers.length} answer(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            // Display attached image if available
            if (mediaPath != null && mediaPath.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${ApiConfig.baseUrl}$mediaPath',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(question['question_text'] ?? '', style: const TextStyle(fontSize: 15)),
            if (answers.isNotEmpty) ...[
              const Divider(height: 24),
              ...answers.map<Widget>((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expert: ${a['expert_name'] ?? 'Expert'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    const SizedBox(height: 4),
                    Text(a['answer_text'] ?? ''),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
