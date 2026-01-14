import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// History screen showing past diagnoses
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _diagnoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(ApiConfig.diagnosisHistory);
      setState(() {
        _diagnoses = List<Map<String, dynamic>>.from(response.data['diagnoses'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diagnoses.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _diagnoses.length,
                    itemBuilder: (context, index) {
                      return _DiagnosisCard(diagnosis: _diagnoses[index]);
                    },
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

  @override
  Widget build(BuildContext context) {
    final severity = diagnosis['severity'] ?? 'moderate';
    final color = AppTheme.getSeverityColor(severity);
    final confidence = ((diagnosis['confidence'] ?? 0) * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.diagnosisResult, arguments: diagnosis),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.eco, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(diagnosis['disease'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(severity.toUpperCase(), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('$confidence% confidence', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
