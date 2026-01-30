import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';

/// Expert Statistics Screen - shows expert's answered questions and ratings
class ExpertStatsScreen extends ConsumerStatefulWidget {
  const ExpertStatsScreen({super.key});

  @override
  ConsumerState<ExpertStatsScreen> createState() => _ExpertStatsScreenState();
}

class _ExpertStatsScreenState extends ConsumerState<ExpertStatsScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _myAnswers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      
      // Load stats
      final statsResponse = await api.get(ApiConfig.expertStats);
      
      // Load answered questions (status=RESOLVED that I answered)
      final answersResponse = await api.get('${ApiConfig.expertQuestions}?status=RESOLVED');
      
      setState(() {
        _stats = statsResponse.data;
        _myAnswers = List<Map<String, dynamic>>.from(answersResponse.data['questions'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Statistics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatsOverview(),
                        const SizedBox(height: 24),
                        _buildRatingsBreakdown(),
                        const SizedBox(height: 24),
                        _buildAnsweredQuestions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsOverview() {
    final totalAnswers = _stats?['total_answers'] ?? 0;
    final avgRating = _stats?['average_rating'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            avgRating != null ? avgRating.toStringAsFixed(1) : '--',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text('Average Rating', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalAnswers Questions Answered',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsBreakdown() {
    final breakdown = _stats?['ratings_breakdown'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ratings Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final rating = 5 - index;
              final count = breakdown['$rating'] ?? 0;
              final total = breakdown.values.fold<int>(0, (sum, v) => sum + (v as int));
              final percentage = total > 0 ? (count / total) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('$rating', style: const TextStyle(fontWeight: FontWeight.w600))),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          color: AppTheme.primaryGreen,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.right)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnsweredQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Answered Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_myAnswers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.question_answer_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No answered questions yet', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          ...List.generate(_myAnswers.length, (index) {
            final q = _myAnswers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                ),
                title: Text(
                  q['question_text'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Asked by: ${q['farmer_name'] ?? 'Farmer'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
