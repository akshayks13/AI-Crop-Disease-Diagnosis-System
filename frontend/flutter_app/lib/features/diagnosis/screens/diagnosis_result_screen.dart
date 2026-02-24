import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/dss_service.dart';
import '../../weather/services/weather_service.dart';

/// Diagnosis result screen with treatment recommendations
class DiagnosisResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> result;

  const DiagnosisResultScreen({super.key, required this.result});

  @override
  ConsumerState<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends ConsumerState<DiagnosisResultScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  int _userRating = 0;
  bool _isRatingSubmitting = false;
  
  // Environmental context and validation
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();

  // DSS Advisory
  Map<String, dynamic>? _dssAdvisory;
  bool _showFarmerInput = false;
  bool _isDssLoading = false;
  String _irrigationLevel = 'Moderate';
  bool _waterlogged = false;
  bool _fertilizerRecent = false;
  bool _firstCycle = false;

  // Weather data
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    // Initialize rating if available given in result (from history)
    if (widget.result['rating'] != null) {
      _userRating = widget.result['rating'] is int ? widget.result['rating'] : int.tryParse(widget.result['rating'].toString()) ?? 0;
    }
    // Load DSS advisory if pre-fetched
    if (widget.result['dss_advisory'] != null) {
      _dssAdvisory = widget.result['dss_advisory'] as Map<String, dynamic>;
    }
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() => _isLoadingWeather = true);
    try {
      final weather = await WeatherService().getCurrentWeather();
      if (mounted) {
        setState(() {
          _weatherData = weather;
          // Auto-fill temperature and humidity in the validation form
          _temperatureController.text = weather.temp.toStringAsFixed(1);
          _humidityController.text = weather.humidity.toString();
          _isLoadingWeather = false;
        });

        // Auto-fetch DSS advisory if not already present (e.g. from history)
        if (_dssAdvisory == null && widget.result['disease_id'] != null) {
          _fetchDssAdvisory(weather);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
        // Still try to fetch DSS without weather data
        if (_dssAdvisory == null && widget.result['disease_id'] != null) {
          _fetchDssAdvisory(null);
        }
      }
    }
  }

  Future<void> _fetchDssAdvisory(WeatherData? weather) async {
    setState(() => _isDssLoading = true);
    try {
      final dssService = ref.read(dssServiceProvider);
      final result = await dssService.getAdvisory(
        diseaseLabel: widget.result['disease_id'],
        temperature: weather?.temp,
        humidity: weather?.humidity,
      );
      if (mounted) {
        setState(() {
          _dssAdvisory = result;
          _isDssLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDssLoading = false);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _temperatureController.dispose();
    _humidityController.dispose();
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



  Future<void> _submitRating(int rating) async {
    if (_isRatingSubmitting) return;

    setState(() {
      _isRatingSubmitting = true;
      _userRating = rating;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final diagnosisId = widget.result['id'];
      await apiClient.post(
        '/diagnosis/$diagnosisId/rate',
        queryParameters: {'rating': rating, 'diagnosis_id': diagnosisId}, 
      );
      // Success feedback handled by UI update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRatingSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disease = widget.result['disease'] ?? 'Unknown';
    final plant = widget.result['plant'] ?? '';
    final severity = widget.result['severity'] ?? 'moderate';
    final rawConfidence = (widget.result['confidence'] as num?)?.toDouble() ?? 0.0;
    final confidence = rawConfidence <= 1.0 ? rawConfidence * 100 : rawConfidence;
    final isHealthy = widget.result['is_healthy'] == true;
    final severityColor = isHealthy ? Colors.green.shade600 : AppTheme.getSeverityColor(severity);

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
                  // Plant name
                  if (plant.isNotEmpty)
                    Text(
                      plant,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (plant.isNotEmpty)
                    const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle : _getSeverityIcon(severity),
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
                        value: isHealthy ? 'NONE' : severity.toUpperCase(),
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        label: 'Confidence',
                        value: '${confidence.toInt()}%',
                        icon: Icons.analytics,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Weather Banner
            _buildWeatherBanner(),

            const SizedBox(height: 16),

            // ── DSS Advisory Section ─────────────────────────────────
            _buildDssAdvisorySection(theme),

            const SizedBox(height: 16),
            
            // Rating Section
            _SectionTitle(title: 'Rate Accuracy', icon: Icons.star_rate_rounded),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  if (_userRating > 0)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Thank you for your feedback! ⭐', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Was this diagnosis helpful?',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500),
                      ),
                    ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= _userRating;
                      return GestureDetector(
                        onTap: () => _submitRating(starIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isSelected ? Colors.amber : Colors.grey.shade300,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  if (_isRatingSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: SizedBox(
                        height: 16, 
                        width: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                    ),
                ],
              ),
            ),
            
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
                      Navigator.pushNamed(
                        context,
                        AppRoutes.askExpert,
                        arguments: widget.result,
                      );
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

  Widget _buildWeatherBanner() {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text('Fetching local weather...', style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
          ],
        ),
      );
    }

    if (_weatherData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Text('Weather unavailable (location permission needed)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    final w = _weatherData!;
    // Disease risk advisory based on weather
    String riskNote;
    Color riskColor;
    IconData riskIcon;
    if (w.humidity > 80 && w.temp > 25) {
      riskNote = 'High humidity + warmth: elevated fungal disease risk';
      riskColor = Colors.red.shade700;
      riskIcon = Icons.warning_amber_rounded;
    } else if (w.humidity > 70) {
      riskNote = 'Moderate humidity: watch for early blight or mildew';
      riskColor = Colors.orange.shade700;
      riskIcon = Icons.info_outline;
    } else {
      riskNote = 'Weather conditions are relatively low-risk for disease spread';
      riskColor = Colors.green.shade700;
      riskIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Current Weather · ${w.cityName}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherStat(icon: Icons.thermostat, label: 'Temp', value: '${w.temp.toStringAsFixed(1)}°C'),
              _WeatherStat(icon: Icons.water_drop, label: 'Humidity', value: '${w.humidity}%'),
              _WeatherStat(icon: Icons.air, label: 'Wind', value: '${w.windSpeed} m/s'),
              _WeatherStat(icon: Icons.cloud, label: 'Condition', value: w.description.split(' ').first),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(riskIcon, size: 14, color: riskColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(riskNote, style: TextStyle(fontSize: 11, color: riskColor, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ],
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

  // ── DSS Advisory Section ────────────────────────────────────────────

  Widget _buildDssAdvisorySection(ThemeData theme) {
    if (_dssAdvisory == null && !_isDssLoading) {
      // No DSS data available — show nothing (ML fallback is already shown)
      return const SizedBox.shrink();
    }

    if (_isDssLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal.shade700)),
            const SizedBox(width: 12),
            Text('Updating advisory...', style: TextStyle(color: Colors.teal.shade700)),
          ],
        ),
      );
    }

    final advisory = _dssAdvisory!;
    final riskScore = (advisory['risk_score'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = advisory['risk_level'] ?? 'Unknown';
    final season = advisory['season'] ?? '';
    final diseaseType = advisory['disease_type'] ?? '';
    final treatments = advisory['treatment_options'] as Map<String, dynamic>? ?? {};
    final chemical = treatments['chemical'] as Map<String, dynamic>? ?? {};
    final organic = treatments['organic'] as Map<String, dynamic>? ?? {};
    final irrigationAdvice = advisory['irrigation_advice'] ?? '';
    final rotationAdvice = advisory['crop_rotation_advice'] ?? '';
    final explanation = advisory['explanation'] ?? '';

    Color riskColor;
    IconData riskIcon;
    if (riskLevel == 'High') {
      riskColor = Colors.red.shade700;
      riskIcon = Icons.warning_amber_rounded;
    } else if (riskLevel == 'Moderate') {
      riskColor = Colors.orange.shade700;
      riskIcon = Icons.info_outline;
    } else {
      riskColor = Colors.green.shade700;
      riskIcon = Icons.check_circle_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'DSS Advisory', icon: Icons.psychology),
        const SizedBox(height: 12),

        // Risk Assessment Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [riskColor.withOpacity(0.1), riskColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: riskColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(riskIcon, color: riskColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Risk Level: $riskLevel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: riskColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(riskScore * 100).toInt()}%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: riskColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Risk progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: riskScore,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: riskColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _DssChip(label: 'Season', value: season, icon: Icons.calendar_today),
                  const SizedBox(width: 8),
                  _DssChip(label: 'Type', value: diseaseType, icon: Icons.bug_report),
                ],
              ),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(explanation, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // DSS Treatment Options
        if (chemical['name'] != null && chemical['name'] != 'None') ...[
          _SectionTitle(title: 'Chemical Treatment (DSS)', icon: Icons.science),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.medication_outlined, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chemical['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      const SizedBox(height: 4),
                      Text('Dosage: ${chemical['dosage'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.blue.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (organic['name'] != null && organic['name'] != 'None') ...[
          _SectionTitle(title: 'Organic Treatment (DSS)', icon: Icons.eco),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.spa_outlined, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(organic['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      const SizedBox(height: 4),
                      Text('Dosage: ${organic['dosage'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.green.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Irrigation & Rotation Advice
        if (irrigationAdvice.isNotEmpty || rotationAdvice.isNotEmpty) ...[
          _SectionTitle(title: 'Prevention & Advice', icon: Icons.shield),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (irrigationAdvice.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.water_drop_outlined, size: 18, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Irrigation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blue.shade800)),
                            const SizedBox(height: 2),
                            Text(irrigationAdvice, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (irrigationAdvice.isNotEmpty && rotationAdvice.isNotEmpty)
                  const Divider(height: 20),
                if (rotationAdvice.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.autorenew, size: 18, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Crop Rotation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.orange.shade800)),
                            const SizedBox(height: 2),
                            Text(rotationAdvice, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Farmer Input Refinement ──────────────────────────────────
        _buildFarmerInputRefinement(theme),
      ],
    );
  }

  Widget _buildFarmerInputRefinement(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showFarmerInput = !_showFarmerInput),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Refine Advisory with Farm Details',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade800, fontSize: 14),
                  ),
                ),
                Icon(
                  _showFarmerInput ? Icons.expand_less : Icons.expand_more,
                  color: Colors.teal.shade700,
                ),
              ],
            ),
          ),
        ),

        if (_showFarmerInput) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Farm Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal.shade800)),
                const SizedBox(height: 14),

                // Irrigation level dropdown
                DropdownButtonFormField<String>(
                  value: _irrigationLevel,
                  decoration: const InputDecoration(
                    labelText: 'Irrigation Level',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Low', 'Moderate', 'Frequent']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _irrigationLevel = v ?? 'Moderate'),
                ),
                const SizedBox(height: 12),

                // Toggle switches
                _FarmToggle(
                  label: 'Field waterlogged recently?',
                  value: _waterlogged,
                  onChanged: (v) => setState(() => _waterlogged = v),
                ),
                _FarmToggle(
                  label: 'Fertilizer applied recently?',
                  value: _fertilizerRecent,
                  onChanged: (v) => setState(() => _fertilizerRecent = v),
                ),
                _FarmToggle(
                  label: 'First crop cycle in this soil?',
                  value: _firstCycle,
                  onChanged: (v) => setState(() => _firstCycle = v),
                ),

                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _isDssLoading ? null : _refreshDssAdvisory,
                  icon: _isDssLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh),
                  label: Text(_isDssLoading ? 'Updating...' : 'Update Advisory'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _refreshDssAdvisory() async {
    if (_isDssLoading) return;
    setState(() => _isDssLoading = true);

    try {
      final dssService = ref.read(dssServiceProvider);
      final result = await dssService.getAdvisory(
        diseaseLabel: widget.result['disease_id'] ?? '',
        temperature: _weatherData?.temp,
        humidity: _weatherData?.humidity,
        irrigation: _irrigationLevel,
        waterlogged: _waterlogged,
        fertilizerRecent: _fertilizerRecent,
        firstCycle: _firstCycle,
      );
      if (mounted) {
        setState(() => _dssAdvisory = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update advisory: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDssLoading = false);
    }
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
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

class _DssChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DssChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

class _FarmToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FarmToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}

