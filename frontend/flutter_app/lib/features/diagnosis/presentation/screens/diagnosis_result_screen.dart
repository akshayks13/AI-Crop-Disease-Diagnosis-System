import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../config/theme.dart';

/// Diagnosis result screen with treatment recommendations
class DiagnosisResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;

  const DiagnosisResultScreen({super.key, required this.result});

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    final text = _buildSpeechText();
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  String _buildSpeechText() {
    final disease = widget.result['disease'] ?? 'Unknown';
    final severity = widget.result['severity'] ?? 'Unknown';
    final steps = widget.result['treatment_steps'] as List? ?? [];

    String speech = 'Diagnosis result: Your crop has $disease with $severity severity. ';

    if (steps.isNotEmpty) {
      speech += 'Treatment steps: ';
      for (var i = 0; i < steps.length && i < 3; i++) {
        speech += 'Step ${i + 1}: ${steps[i]['description']}. ';
      }
    }

    return speech;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disease = widget.result['disease'] ?? 'Unknown';
    final severity = widget.result['severity'] ?? 'moderate';
    final confidence = (widget.result['confidence'] as num?)?.toDouble() ?? 0.0;
    final severityColor = AppTheme.getSeverityColor(severity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
            tooltip: 'Read aloud',
            onPressed: _speak,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disease header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [severityColor, severityColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: severityColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSeverityIcon(severity),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          disease,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(
                        label: 'Severity',
                        value: severity.toUpperCase(),
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        label: 'Confidence',
                        value: '${(confidence * 100).toInt()}%',
                        icon: Icons.analytics,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Warning if present
            if (widget.result['warnings'] != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.result['warnings'],
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Treatment steps
            _SectionTitle(title: 'Treatment Steps', icon: Icons.checklist),
            const SizedBox(height: 12),
            _TreatmentSteps(
              steps: (widget.result['treatment_steps'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [],
            ),

            const SizedBox(height: 24),

            // Chemical options
            if ((widget.result['chemical_options'] as List?)?.isNotEmpty ?? false) ...[
              _SectionTitle(title: 'Chemical Treatment', icon: Icons.science),
              const SizedBox(height: 12),
              _TreatmentOptions(
                options: (widget.result['chemical_options'] as List)
                    .cast<Map<String, dynamic>>(),
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
            ],

            // Organic options
            if ((widget.result['organic_options'] as List?)?.isNotEmpty ?? false) ...[
              _SectionTitle(title: 'Organic Treatment', icon: Icons.eco),
              const SizedBox(height: 12),
              _TreatmentOptions(
                options: (widget.result['organic_options'] as List)
                    .cast<Map<String, dynamic>>(),
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 24),
            ],

            // Prevention
            if (widget.result['prevention'] != null) ...[
              _SectionTitle(title: 'Prevention', icon: Icons.shield),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(widget.result['prevention']),
              ),
            ],

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('New Scan'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to ask expert with this diagnosis
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Ask Expert'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Icons.check_circle;
      case 'moderate':
        return Icons.warning;
      case 'severe':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _TreatmentSteps extends StatelessWidget {
  final List<Map<String, dynamic>> steps;

  const _TreatmentSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final step = steps[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              radius: 14,
              child: Text(
                '${step['step_number'] ?? index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(step['description'] ?? ''),
            subtitle: step['timing'] != null
                ? Text(
                    step['timing'],
                    style: TextStyle(color: AppTheme.accentOrange),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _TreatmentOptions extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Color color;

  const _TreatmentOptions({required this.options, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option['name'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (option['dosage'] != null)
                _DetailRow(label: 'Dosage', value: option['dosage']),
              if (option['application_method'] != null)
                _DetailRow(label: 'Method', value: option['application_method']),
              if (option['frequency'] != null)
                _DetailRow(label: 'Frequency', value: option['frequency']),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
