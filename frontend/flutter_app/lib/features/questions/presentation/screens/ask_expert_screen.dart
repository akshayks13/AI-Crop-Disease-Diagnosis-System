import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Ask Expert screen for submitting questions
class AskExpertScreen extends ConsumerStatefulWidget {
  const AskExpertScreen({super.key});

  @override
  ConsumerState<AskExpertScreen> createState() => _AskExpertScreenState();
}

class _AskExpertScreenState extends ConsumerState<AskExpertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConfig.questions, data: {'question_text': _questionController.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question submitted! An expert will respond soon.'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask an Expert')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.support_agent, color: AppTheme.accentOrange, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Get personalized advice from certified agricultural experts.')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _questionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Your Question',
                  hintText: 'Describe your crop issue in detail...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.length < 10 ? 'Please provide more details (min 10 characters)' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitQuestion,
                  icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Question'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
