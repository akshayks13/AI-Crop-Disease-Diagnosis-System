import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';

/// Screen showing questions answered by the current expert
class AnsweredQuestionsScreen extends ConsumerStatefulWidget {
  const AnsweredQuestionsScreen({super.key});

  @override
  ConsumerState<AnsweredQuestionsScreen> createState() => _AnsweredQuestionsScreenState();
}

class _AnsweredQuestionsScreenState extends ConsumerState<AnsweredQuestionsScreen> {
  List<Map<String, dynamic>> _answers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(ApiConfig.expertMyAnswers);
      
      if (mounted) {
        setState(() {
          _answers = List<Map<String, dynamic>>.from(response.data['answers'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Answered Questions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _answers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAnswers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _answers.length,
                        itemBuilder: (context, index) {
                          return _buildAnswerCard(_answers[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No answered questions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start answering relevant questions to see them here.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(Map<String, dynamic> item) {
    final hasImage = item['media_path'] != null;
    final rating = item['rating'];

    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.expertAnswerDetail, arguments: item),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Farmer Info & Rating
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      (item['farmer_name'] ?? 'F')[0].toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['farmer_name'] ?? 'Unknown Farmer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Answered on ${_formatDate(item['answered_at'])}',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$rating/5', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ],
              ),
            ),
            
            const Divider(height: 1),

            // Question Snippet
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Q: ', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                      Expanded(
                        child: Text(
                            item['question_text'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                      ),
                    ],
                   ),
                   if (hasImage) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.image, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text('Contains Image', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                        ],
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
