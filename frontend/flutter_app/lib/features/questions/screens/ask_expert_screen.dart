import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Ask Expert screen for submitting questions with optional image/video
class AskExpertScreen extends ConsumerStatefulWidget {
  final String? diagnosisId;
  final Map<String, dynamic>? diagnosisInfo;
  
  const AskExpertScreen({super.key, this.diagnosisId, this.diagnosisInfo});

  @override
  ConsumerState<AskExpertScreen> createState() => _AskExpertScreenState();
}

class _AskExpertScreenState extends ConsumerState<AskExpertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  bool _isSubmitting = false;
  XFile? _selectedMedia;
  String? _mediaType; // 'image' or 'video'

  final ImagePicker _picker = ImagePicker();

  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.baseUrl}$path';
  }

  @override
  void initState() {
    super.initState();
    if (widget.diagnosisInfo != null) {
      final disease = widget.diagnosisInfo!['disease'] ?? 'Unknown condition';
      final crop = widget.diagnosisInfo!['crop_type'] ?? 'crop';
      _questionController.text = "I have a problem with my $crop. Diagnosis suggests it's $disease. Can you help with treatment?";
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedMedia = image;
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      setState(() {
        _selectedMedia = video;
        _mediaType = 'video';
      });
    }
  }

  void _clearMedia() {
    setState(() {
      _selectedMedia = null;
      _mediaType = null;
    });
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiClientProvider);
      
      if (_selectedMedia != null) {
        // Read file bytes for cross-platform compatibility (web, mobile, desktop)
        final bytes = await _selectedMedia!.readAsBytes();
        final formData = FormData.fromMap({
          'question_text': _questionController.text.trim(),
          if (widget.diagnosisId != null) 'diagnosis_id': widget.diagnosisId,
          'file': MultipartFile.fromBytes(
            bytes,
            filename: _selectedMedia!.name,
          ),
        });
        await api.post('${ApiConfig.questions}/with-file', data: formData);
      } else {
        // Text-only question
        final data = {
          'question_text': _questionController.text.trim(),
          if (widget.diagnosisId != null) 'diagnosis_id': widget.diagnosisId,
        };
        await api.post(ApiConfig.questions, data: data);
      }
      
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your question';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Media attachment section
              Text('Attach Photo/Video (Optional)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              
              if (_selectedMedia == null)
                if (widget.diagnosisInfo?['media_path'] != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _resolveImageUrl(widget.diagnosisInfo!['media_path'] as String),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 60, height: 60, 
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diagnosis Image Attached',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                              ),
                              Text(
                                'Will be submitted with your question',
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                              ),
                            ],
                          ),
                        ),
                        // Allow user to clear/replace if needed (conceptually replacing invalidates diagnosis link image-wise, but we just let them add NEW image which overrides)
                      ],
                    ),
                  ),

              if (_selectedMedia == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera),
                        label: Text(widget.diagnosisInfo?['media_path'] != null ? 'Replace Image' : 'Add Image'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.videocam),
                        label: const Text('Add Video'),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _mediaType == 'video' ? Icons.videocam : Icons.image,
                        color: AppTheme.primaryGreen,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mediaType == 'video' ? 'Video attached' : 'Image attached',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _selectedMedia!.name,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _clearMedia,
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
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
