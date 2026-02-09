import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/encyclopedia_provider.dart';

class EncyclopediaScreen extends ConsumerStatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  ConsumerState<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends ConsumerState<EncyclopediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getSearchHint() {
    if (_tabController.index == 0) {
      // Crops tab
      return 'Search by crop name or scientific name (e.g., Corn, Zea mays)';
    } else {
      // Diseases tab
      return 'Search by disease name (e.g., Early blight, Rust)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final encState = ref.watch(encyclopediaProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Encyclopedia'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Crops', icon: Icon(Icons.eco)),
            Tab(text: 'Diseases', icon: Icon(Icons.bug_report)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: TextField(
              controller: _searchController,
              // Typed text color
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.primary,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              onChanged: (value) {
                ref.read(encyclopediaProvider.notifier).setSearchQuery(value);
              },
            ),
          ),


          // Content
          Expanded(
            child: encState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : encState.error != null
                    ? _buildErrorWidget(colorScheme)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCropsGrid(encState, colorScheme),
                          _buildDiseasesList(encState, colorScheme),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropsGrid(EncyclopediaState state, ColorScheme colorScheme) {
    final crops = state.filteredCrops;
    
    if (crops.isEmpty) {
      return _buildEmptyWidget('No crops found', colorScheme);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final crop = crops[index];
        return _buildCropCard(crop, colorScheme);
      },
    );
  }

  Widget _buildCropCard(CropInfo crop, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showCropDetail(crop),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crop Image/Icon
            Container(
              height: 100,
              color: colorScheme.primaryContainer,
              child: Center(
                child: Icon(
                  Icons.eco,
                  size: 50,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            
            // Crop Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (crop.scientificName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        crop.scientificName!,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeasonColor(crop.season, colorScheme).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        crop.season ?? 'All Season',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getSeasonColor(crop.season, colorScheme),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeasonColor(String? season, ColorScheme colorScheme) {
    if (season == null) return colorScheme.outline;
    final lower = season.toLowerCase();
    if (lower.contains('kharif')) return colorScheme.primary;
    if (lower.contains('rabi')) return colorScheme.tertiary; // Orange-ish usually via tertiary/secondary
    return colorScheme.secondary;
  }

  Widget _buildDiseasesList(EncyclopediaState state, ColorScheme colorScheme) {
    final diseases = state.filteredDiseases;
    
    if (diseases.isEmpty) {
      return _buildEmptyWidget('No diseases found', colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diseases.length,
      itemBuilder: (context, index) {
        final disease = diseases[index];
        return _buildDiseaseCard(disease, colorScheme);
      },
    );
  }

  Widget _buildDiseaseCard(DiseaseInfo disease, ColorScheme colorScheme) {
    final severityColor = _getSeverityColor(disease.severityLevel, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDiseaseDetail(disease),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bug_report, color: colorScheme.onErrorContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Affects: ${disease.affectedCrops.join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (disease.severityLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    disease.severityLevel!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String? severity, ColorScheme colorScheme) {
      if (severity == 'mild') return Colors.yellow.shade700; // Keep explicit for mild warning
      if (severity == 'moderate') return Colors.orange;
      if (severity == 'severe') return colorScheme.error;
      return colorScheme.outline;
  }

  void _showCropDetail(CropInfo crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.eco, color: colorScheme.onPrimaryContainer, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            if (crop.scientificName != null)
                              Text(
                                crop.scientificName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (crop.description != null) ...[
                    Text(crop.description!, style: TextStyle(color: colorScheme.onSurface, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Growing Conditions
                  _buildSectionTitle('Growing Conditions', colorScheme),
                  _buildInfoRow(Icons.thermostat, 'Temperature', crop.temperatureRange, colorScheme),
                  _buildInfoRow(Icons.water_drop, 'Water', crop.waterRequirement ?? 'N/A', colorScheme),
                  _buildInfoRow(Icons.landscape, 'Soil', crop.soilType ?? 'N/A', colorScheme),
                  _buildInfoRow(Icons.calendar_month, 'Season', crop.season ?? 'N/A', colorScheme),
                  const SizedBox(height: 16),

                  // Growing Tips
                  if (crop.growingTips.isNotEmpty) ...[
                    _buildSectionTitle('Growing Tips', colorScheme),
                    ...crop.growingTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb, size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Common Diseases
                  if (crop.commonDiseases.isNotEmpty) ...[
                    _buildSectionTitle('Common Diseases', colorScheme),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: crop.commonDiseases.map((d) => Chip(
                        label: Text(d, style: const TextStyle(fontSize: 12)),
                        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.5),
                        avatar: Icon(Icons.warning, size: 14, color: colorScheme.error),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDiseaseDetail(DiseaseInfo disease) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
         final theme = Theme.of(context);
         final colorScheme = theme.colorScheme;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Text(disease.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (disease.scientificName != null)
                    Text(disease.scientificName!, style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  // Affected Crops
                  Wrap(
                    spacing: 8,
                    children: disease.affectedCrops.map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (disease.description != null) ...[
                    Text(disease.description!, style: TextStyle(color: colorScheme.onSurface, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Symptoms
                  if (disease.symptoms.isNotEmpty) ...[
                    _buildSectionTitle('Symptoms', colorScheme),
                    ...disease.symptoms.map((s) => _buildBulletPoint(s, Icons.visibility, colorScheme)),
                    const SizedBox(height: 16),
                  ],

                  // Treatments
                  if (disease.organicTreatment.isNotEmpty) ...[
                    _buildSectionTitle('Organic Treatment', colorScheme),
                    ...disease.organicTreatment.map((t) => _buildBulletPoint(t, Icons.nature, colorScheme)),
                    const SizedBox(height: 12),
                  ],
                  if (disease.chemicalTreatment.isNotEmpty) ...[
                    _buildSectionTitle('Chemical Treatment', colorScheme),
                    ...disease.chemicalTreatment.map((t) => _buildBulletPoint(t, Icons.science, colorScheme)),
                    const SizedBox(height: 12),
                  ],

                  // Prevention
                  if (disease.prevention.isNotEmpty) ...[
                    _buildSectionTitle('Prevention', colorScheme),
                    ...disease.prevention.map((p) => _buildBulletPoint(p, Icons.shield, colorScheme)),
                    const SizedBox(height: 12),
                  ],

                  // Warnings
                  if (disease.safetyWarnings.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100, // Explicit warning color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.amber.shade900),
                              const SizedBox(width: 8),
                              Text('Safety Warnings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...disease.safetyWarnings.map((w) => Text('• $w', style: TextStyle(color: Colors.amber.shade900))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          const Text('Failed to load encyclopedia'),
          ElevatedButton(
            onPressed: () => ref.read(encyclopediaProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
