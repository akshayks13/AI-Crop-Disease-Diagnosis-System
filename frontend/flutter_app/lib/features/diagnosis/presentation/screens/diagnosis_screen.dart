import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Diagnosis screen with camera capture
class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  File? _selectedImage;
  String? _cropType;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _cropTypes = [
    'Tomato',
    'Potato',
    'Corn',
    'Wheat',
    'Rice',
    'Cotton',
    'Other',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeCrop() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.uploadFile(
        ApiConfig.predict,
        file: _selectedImage!,
        fields: {
          if (_cropType != null) 'crop_type': _cropType,
        },
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.diagnosisResult,
          arguments: response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnose Crop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Take a clear photo of the affected plant part for accurate diagnosis.',
                      style: TextStyle(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Image preview / capture area
            GestureDetector(
              onTap: () => _showImagePickerOptions(),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _selectedImage = null);
                                },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to capture or select image',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Crop type selector
            Text(
              'Crop Type (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cropTypes.map((crop) {
                final isSelected = _cropType == crop.toLowerCase();
                return ChoiceChip(
                  label: Text(crop),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _cropType = selected ? crop.toLowerCase() : null;
                    });
                  },
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Analyze button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isProcessing
                    ? _analyzeCrop
                    : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.science_outlined),
                label: Text(_isProcessing ? 'Analyzing...' : 'Analyze Crop'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
