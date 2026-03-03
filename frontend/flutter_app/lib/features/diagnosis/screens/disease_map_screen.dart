import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

/// Disease Outbreak Map — shows geo-tagged diagnosis markers on OSM tiles.
class DiseaseMapScreen extends ConsumerStatefulWidget {
  const DiseaseMapScreen({super.key});

  @override
  ConsumerState<DiseaseMapScreen> createState() => _DiseaseMapScreenState();
}

class _DiseaseMapScreenState extends ConsumerState<DiseaseMapScreen> {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _outbreaks = [];
  List<String> _diseases = [];
  String? _selectedDisease;
  bool _isLoading = true;
  String? _error;

  // Default center: India
  LatLng _center = const LatLng(20.5937, 78.9629);
  double _zoom = 5.0;

  @override
  void initState() {
    super.initState();
    _fetchOutbreaks();
    _goToCurrentLocation();
  }

  // ── Data ──────────────────────────────────────────────────────────────

  Future<void> _fetchOutbreaks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{'days': 30};
      if (_selectedDisease != null) params['disease'] = _selectedDisease;

      final response = await api.get('/diagnosis/disease-map', queryParameters: params);
      final data = response.data as Map<String, dynamic>;

      setState(() {
        _outbreaks = List<Map<String, dynamic>>.from(data['outbreaks'] ?? []);
        _diseases = List<String>.from(data['diseases'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load outbreak data';
        _isLoading = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _zoom = 10.0;
      });
      _mapController.move(_center, _zoom);
    } catch (_) {
      // Silently fall back to default center
    }
  }

  // ── Marker helpers ────────────────────────────────────────────────────

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Icons.error;
      case 'moderate':
        return Icons.warning;
      case 'mild':
        return Icons.info;
      default:
        return Icons.place;
    }
  }

  List<Marker> _buildMarkers() {
    return _outbreaks.map((o) {
      final color = _severityColor(o['severity'] ?? 'moderate');
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(
          (o['latitude'] as num).toDouble(),
          (o['longitude'] as num).toDouble(),
        ),
        child: GestureDetector(
          onTap: () => _showOutbreakDetail(o),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(_severityIcon(o['severity'] ?? ''), color: Colors.white, size: 20),
          ),
        ),
      );
    }).toList();
  }

  void _showOutbreakDetail(Map<String, dynamic> o) {
    final color = _severityColor(o['severity'] ?? 'moderate');
    final dateStr = o['date'] ?? '';
    final dateFormatted = dateStr.isNotEmpty
        ? DateTime.tryParse(dateStr)?.toLocal().toString().split('.').first ?? dateStr
        : 'Unknown';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_severityIcon(o['severity'] ?? ''), color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o['disease'] ?? 'Unknown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                      const SizedBox(height: 2),
                      Text('Severity: ${(o['severity'] ?? 'Unknown').toString().toUpperCase()}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.grass, label: 'Crop', value: o['crop_type'] ?? 'Not specified'),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.calendar_today, label: 'Detected', value: dateFormatted),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.location_on, label: 'Coordinates', value: '${(o['latitude'] as num).toStringAsFixed(4)}, ${(o['longitude'] as num).toStringAsFixed(4)}'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Outbreak Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'My Location',
            onPressed: _goToCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchOutbreaks,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────
          if (_diseases.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedDisease == null,
                      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                      onSelected: (_) {
                        setState(() => _selectedDisease = null);
                        _fetchOutbreaks();
                      },
                    ),
                  ),
                  ..._diseases.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(d),
                      selected: _selectedDisease == d,
                      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                      onSelected: (_) {
                        setState(() => _selectedDisease = d);
                        _fetchOutbreaks();
                      },
                    ),
                  )),
                ],
              ),
            ),

          // ── Map ───────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _fetchOutbreaks,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _center,
                              initialZoom: _zoom,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.cropdiagnosis.app',
                                tileProvider: CancellableNetworkTileProvider(),
                              ),
                              MarkerLayer(markers: _buildMarkers()),
                            ],
                          ),

                          // ── Legend ────────────────────────────────
                          Positioned(
                            bottom: 24,
                            left: 16,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.insights, size: 16, color: Colors.grey.shade800),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_outbreaks.length} Reports (30 Days)',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const _LegendItem(color: Colors.red, label: 'Severe', icon: Icons.error),
                                      const SizedBox(height: 4),
                                      const _LegendItem(color: Colors.orange, label: 'Moderate', icon: Icons.warning),
                                      const SizedBox(height: 4),
                                      const _LegendItem(color: Colors.green, label: 'Mild', icon: Icons.info),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendItem({required this.color, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
