import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../config/routes.dart';
import '../../../../core/services/ml_service.dart';
import '../../../../core/api/dss_service.dart';
import '../../../../core/api/api_client.dart';
import '../../weather/services/weather_service.dart';

/// Diagnosis screen with camera capture and voice symptom input
class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  // Voice input
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  final TextEditingController _symptomsController = TextEditingController();
  bool _showVoiceSection = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Check mic permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input')),
        );
      }
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available on this device')),
          );
        }
        return;
      }
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _symptomsController.text = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_IN', // Indian English for better accuracy with farming terms
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _analyzeCrop() async {
    if (_selectedImage == null || _imageBytes == null) return;

    setState(() => _isProcessing = true);

    try {
      final mlService = ref.read(mlServiceProvider);
      await mlService.initialize();
      final result = await mlService.predict(_selectedImage!);

      // Attach symptoms description to result if provided
      if (_symptomsController.text.trim().isNotEmpty) {
        result['farmer_symptoms'] = _symptomsController.text.trim();
      }

      // Fetch weather + DSS advisory in parallel
      try {
        final weatherFuture = WeatherService().getCurrentWeather();
        final weather = await weatherFuture;

        final dssService = ref.read(dssServiceProvider);
        final dssResult = await dssService.getAdvisory(
          diseaseLabel: result['disease_id'] ?? '',
          temperature: weather.temp,
          humidity: weather.humidity,
        );

        // Merge DSS advisory into the result
        result['dss_advisory'] = dssResult;

        // Persist DSS advisory + TFLite data to backend for history
        if (result['id'] != null) {
          try {
            final api = ref.read(apiClientProvider);

            // Capture GPS for outbreak map (non-blocking)
            double? lat, lng;
            try {
              final perm = await Geolocator.checkPermission();
              if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
                final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium)
                    .timeout(const Duration(seconds: 3));
                lat = pos.latitude;
                lng = pos.longitude;
              }
            } catch (_) {}

            await api.post(
              '/diagnosis/${result['id']}/save-advisory',
              data: {
                'disease_id': result['disease_id'],
                'dss_advisory': dssResult,
                'disease': result['disease'],
                'plant': result['plant'],
                'confidence': result['confidence'],
                'severity': result['severity'],
                if (lat != null) 'latitude': lat,
                if (lng != null) 'longitude': lng,
              },
            );
          } catch (_) {
            // Non-critical — don't block navigation
          }
        }
      } catch (e) {
        // DSS is supplementary — don't block navigation if it fails
        debugPrint('DSS advisory fetch failed: $e');
      }

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.diagnosisResult,
          arguments: result,
        );
      }
    } catch (e) {
      String errorMessage = 'Error analyzing image';
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String? detail;
        if (data is Map && data['detail'] != null) {
          detail = data['detail'].toString();
        }

        if (detail != null && detail.isNotEmpty) {
          errorMessage = detail;
        } else if (status != null) {
          errorMessage = 'Server error ($status). Please try again.';
        } else {
          errorMessage = 'Network error. Check backend URL and connectivity.';
        }
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
    final colorScheme = theme.colorScheme;

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
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Take a clear photo of the affected plant part for accurate diagnosis.',
                      style: TextStyle(color: colorScheme.primary),
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
                constraints: const BoxConstraints(minHeight: 280),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _imageBytes != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 400),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
                                const SizedBox(width: 8),
                                Text(
                                  'Remove Image',
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        height: 280,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to capture or select image',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Voice Input Section ──────────────────────────────────────────
            _buildVoiceInputSection(colorScheme),

            const SizedBox(height: 24),

            // Analyze button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isProcessing
                    ? _analyzeCrop
                    : null,
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.science_outlined),
                label: Text(_isProcessing ? 'Analyzing...' : 'Analyze Crop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle header
        InkWell(
          onTap: () => setState(() => _showVoiceSection = !_showVoiceSection),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.secondaryContainer),
            ),
            child: Row(
              children: [
                Icon(Icons.mic_outlined, color: colorScheme.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Describe Symptoms (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 14,
                        ),
                      ),
                      if (_symptomsController.text.isNotEmpty)
                        Text(
                          '"${_symptomsController.text.length > 40 ? '${_symptomsController.text.substring(0, 40)}...' : _symptomsController.text}"',
                          style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showVoiceSection ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),

        // Expanded voice input
        if (_showVoiceSection) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mic button + status
                Row(
                  children: [
                    // Animated mic button
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? Colors.red.shade400
                              : colorScheme.primaryContainer,
                          boxShadow: _isListening
                              ? [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
                              : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.white : colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isListening
                                ? '🔴 Listening... speak now'
                                : 'Tap mic to describe symptoms',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isListening ? Colors.red.shade700 : colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _isListening
                                ? 'Tap again to stop'
                                : 'e.g., "yellow spots on leaves, wilting"',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Text field for transcribed / manual input
                TextField(
                  controller: _symptomsController,
                  maxLines: 3,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Transcribed text will appear here, or type manually...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    suffixIcon: _symptomsController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _symptomsController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                if (_symptomsController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${_symptomsController.text.split(' ').where((w) => w.isNotEmpty).length} words recorded',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showImagePickerOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: colorScheme.onPrimaryContainer),
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
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library, color: colorScheme.onSecondaryContainer),
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
