import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// History screen showing past diagnoses with filters and dates
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _allDiagnoses = [];
  List<Map<String, dynamic>> _filteredDiagnoses = [];
  bool _isLoading = true;

  // Filters
  String _severityFilter = 'All';
  String _sortOrder = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(ApiConfig.diagnosisHistory);
      final diagnoses = List<Map<String, dynamic>>.from(response.data['diagnoses'] ?? []);
      setState(() {
        _allDiagnoses = diagnoses;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Normalize severity — backend may use different values
  static String _normalizeSeverity(String? raw) {
    final s = (raw ?? 'moderate').toLowerCase();
    // Map high/medium/low (TFLite) → severe/moderate/mild (backend canonical)
    switch (s) {
      case 'high':
      case 'severe':
        return 'severe';
      case 'medium':
      case 'moderate':
        return 'moderate';
      case 'low':
      case 'mild':
        return 'mild';
      case 'none':
        return 'none';
      default:
        return 'moderate';
    }
  }

  void _applyFilters() {
    var result = List<Map<String, dynamic>>.from(_allDiagnoses);

    // Severity filter
    if (_severityFilter != 'All') {
      result = result.where((d) {
        return _normalizeSeverity(d['severity']) == _severityFilter.toLowerCase();
      }).toList();
    }

    // Sort
    if (_sortOrder == 'Oldest') {
      result.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));
    } else {
      result.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    }

    _filteredDiagnoses = result;
  }

  int _countBySeverity(String target) {
    return _allDiagnoses.where((d) => _normalizeSeverity(d['severity']) == target).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (value) {
              setState(() {
                _sortOrder = value;
                _applyFilters();
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'Newest', child: Row(children: [
                Icon(_sortOrder == 'Newest' ? Icons.check : Icons.sort, size: 18),
                const SizedBox(width: 8),
                const Text('Newest first'),
              ])),
              PopupMenuItem(value: 'Oldest', child: Row(children: [
                Icon(_sortOrder == 'Oldest' ? Icons.check : Icons.sort, size: 18),
                const SizedBox(width: 8),
                const Text('Oldest first'),
              ])),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allDiagnoses.isEmpty
              ? _EmptyState()
              : Column(
                  children: [
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            count: _allDiagnoses.length,
                            isSelected: _severityFilter == 'All',
                            onTap: () => setState(() { _severityFilter = 'All'; _applyFilters(); }),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Severe',
                            count: _countBySeverity('severe'),
                            isSelected: _severityFilter == 'Severe',
                            color: AppTheme.severeSeverity,
                            onTap: () => setState(() { _severityFilter = 'Severe'; _applyFilters(); }),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Moderate',
                            count: _countBySeverity('moderate'),
                            isSelected: _severityFilter == 'Moderate',
                            color: AppTheme.moderateSeverity,
                            onTap: () => setState(() { _severityFilter = 'Moderate'; _applyFilters(); }),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Mild',
                            count: _countBySeverity('mild'),
                            isSelected: _severityFilter == 'Mild',
                            color: AppTheme.mildSeverity,
                            onTap: () => setState(() { _severityFilter = 'Mild'; _applyFilters(); }),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Healthy',
                            count: _countBySeverity('none'),
                            isSelected: _severityFilter == 'None',
                            color: Colors.teal,
                            onTap: () => setState(() { _severityFilter = 'None'; _applyFilters(); }),
                          ),
                        ],
                      ),
                    ),

                    // Results count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredDiagnoses.length} diagnosis${_filteredDiagnoses.length == 1 ? '' : 'es'}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // List
                    Expanded(
                      child: _filteredDiagnoses.isEmpty
                          ? Center(
                              child: Text('No diagnoses match this filter',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                itemCount: _filteredDiagnoses.length,
                                itemBuilder: (context, index) {
                                  return _DiagnosisCard(diagnosis: _filteredDiagnoses[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade400,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? chipColor : Colors.grey.shade600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? chipColor.withOpacity(0.2) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? chipColor : Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No diagnosis history yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.diagnosis),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start your first diagnosis'),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  const _DiagnosisCard({required this.diagnosis});

  /// Parse UTC timestamp from backend and convert to local time
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      // Backend stores UTC timestamps without 'Z' suffix — append it
      final utcStr = dateStr.endsWith('Z') ? dateStr : '${dateStr}Z';
      final dt = DateTime.parse(utcStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  int _getConfidencePercent() {
    final raw = (diagnosis['confidence'] as num?)?.toDouble() ?? 0.0;
    // Backend stores 0-1, TFLite returns 0-100 — normalize
    if (raw <= 1.0) return (raw * 100).toInt();
    return raw.toInt();
  }

  /// Normalize severity to canonical form
  String _getNormalizedSeverity() {
    return _HistoryScreenState._normalizeSeverity(diagnosis['severity']);
  }

  /// Get display label for severity
  String _getSeverityLabel() {
    final s = _getNormalizedSeverity();
    switch (s) {
      case 'severe': return 'SEVERE';
      case 'moderate': return 'MODERATE';
      case 'mild': return 'MILD';
      case 'none': return 'HEALTHY';
      default: return s.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disease = diagnosis['disease'] ?? 'Unknown';
    final plant = diagnosis['plant'] ?? diagnosis['crop_type'] ?? '';
    final normalizedSeverity = _getNormalizedSeverity();
    final color = AppTheme.getSeverityColor(normalizedSeverity);
    final confidence = _getConfidencePercent();
    final dateStr = _formatDate(diagnosis['created_at']);
    final hasDss = diagnosis['dss_advisory'] != null;
    final rating = diagnosis['rating'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.diagnosisResult, arguments: diagnosis),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Severity indicator
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.eco, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease name
                    Text(
                      disease,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Plant name + date
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (plant.toString().isNotEmpty) ...[
                          Icon(Icons.grass, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            plant.toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (dateStr.isNotEmpty) ...[
                          Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),

                    // Severity + Confidence + extra badges
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getSeverityLabel(),
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$confidence%',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        if (hasDss) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.verified, size: 14, color: Colors.teal.shade400),
                        ],
                        if (rating != null && rating > 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(' $rating', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
