import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';

/// Trending Diseases Screen - Shows most diagnosed diseases
class TrendingDiseasesScreen extends ConsumerStatefulWidget {
  const TrendingDiseasesScreen({super.key});

  @override
  ConsumerState<TrendingDiseasesScreen> createState() => _TrendingDiseasesScreenState();
}

class _TrendingDiseasesScreenState extends ConsumerState<TrendingDiseasesScreen> {
  List<Map<String, dynamic>> _trending = [];
  bool _isLoading = true;
  String _period = 'week';

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/expert/trending-diseases', queryParameters: {'period': _period});
      if (mounted) {
        setState(() {
          _trending = List<Map<String, dynamic>>.from(response.data['trending'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Diseases'),
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPeriodChip('week', 'This Week'),
                const SizedBox(width: 8),
                _buildPeriodChip('month', 'This Month'),
                const SizedBox(width: 8),
                _buildPeriodChip('all', 'All Time'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trending.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_up, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('No trending data', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTrending,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _trending.length,
                          itemBuilder: (context, index) {
                            final item = _trending[index];
                            final count = item['diagnosis_count'] ?? 0;
                            final maxCount = _trending.isNotEmpty ? (_trending[0]['diagnosis_count'] ?? 1) : 1;
                            final percentage = (count / maxCount) * 100;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _getRankColor(index).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '#${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _getRankColor(index),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item['disease_name'] ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Text(
                                          '$count diagnoses',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                        minHeight: 8,
                                      ),
                                    ),
                                    if (item['question_count'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '${item['question_count']} related questions',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _period == value;
    final theme = Theme.of(context);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _period = value);
          _loadTrending();
        }
      },
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}
