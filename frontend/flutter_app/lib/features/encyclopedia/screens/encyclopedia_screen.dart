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
    setState(() {}); // 🔄 refresh UI when tab changes
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Encyclopedia'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Crops', icon: Icon(Icons.eco)),
            Tab(text: 'Diseases', icon: Icon(Icons.bug_report)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: TextField(
              controller: _searchController,

              // Typed text color
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),

              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.green.shade700,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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
                    ? _buildErrorWidget()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCropsGrid(encState),
                          _buildDiseasesList(encState),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropsGrid(EncyclopediaState state) {
    final crops = state.filteredCrops;
    
    if (crops.isEmpty) {
      return _buildEmptyWidget('No crops found');
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
        return _buildCropCard(crop);
      },
    );
  }

  Widget _buildCropCard(CropInfo crop) {
    return GestureDetector(
      onTap: () => _showCropDetail(crop),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crop Image/Icon
            Container(
              height: 100,
              color: Colors.green.shade100,
              child: Center(
                child: Icon(
                  Icons.eco,
                  size: 50,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            
            // Crop Info
            Padding(
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
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeasonColor(crop.season).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      crop.season ?? 'All Season',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getSeasonColor(crop.season),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeasonColor(String? season) {
    if (season == null) return Colors.grey;
    final lower = season.toLowerCase();
    if (lower.contains('kharif')) return Colors.green.shade700;
    if (lower.contains('rabi')) return Colors.orange.shade700;
    return Colors.blue.shade700;
  }

  Widget _buildDiseasesList(EncyclopediaState state) {
    final diseases = state.filteredDiseases;
    
    if (diseases.isEmpty) {
      return _buildEmptyWidget('No diseases found');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diseases.length,
      itemBuilder: (context, index) {
        final disease = diseases[index];
        return _buildDiseaseCard(disease);
      },
    );
  }

  Widget _buildDiseaseCard(DiseaseInfo disease) {
    final severityColors = {
      'mild': Colors.yellow.shade700,
      'moderate': Colors.orange,
      'severe': Colors.red,
    };

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
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bug_report, color: Colors.red.shade700, size: 28),
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
                        color: Colors.grey.shade600,
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
                    color: (severityColors[disease.severityLevel] ?? Colors.grey).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    disease.severityLevel!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColors[disease.severityLevel] ?? Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCropDetail(CropInfo crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                        color: Colors.grey.shade300,
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
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.eco, color: Colors.green.shade700, size: 32),
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
                                  color: Colors.grey.shade600,
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
                    Text(crop.description!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Growing Conditions
                  _buildSectionTitle('Growing Conditions'),
                  _buildInfoRow(Icons.thermostat, 'Temperature', crop.temperatureRange),
                  _buildInfoRow(Icons.water_drop, 'Water', crop.waterRequirement ?? 'N/A'),
                  _buildInfoRow(Icons.landscape, 'Soil', crop.soilType ?? 'N/A'),
                  _buildInfoRow(Icons.calendar_month, 'Season', crop.season ?? 'N/A'),
                  const SizedBox(height: 16),

                  // Growing Tips
                  if (crop.growingTips.isNotEmpty) ...[
                    _buildSectionTitle('Growing Tips'),
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
                    _buildSectionTitle('Common Diseases'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: crop.commonDiseases.map((d) => Chip(
                        label: Text(d, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.red.shade50,
                        avatar: Icon(Icons.warning, size: 14, color: Colors.red.shade700),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Text(disease.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (disease.scientificName != null)
                    Text(disease.scientificName!, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),

                  // Affected Crops
                  Wrap(
                    spacing: 8,
                    children: disease.affectedCrops.map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.green.shade50,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (disease.description != null) ...[
                    Text(disease.description!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Symptoms
                  if (disease.symptoms.isNotEmpty) ...[
                    _buildSectionTitle('Symptoms'),
                    ...disease.symptoms.map((s) => _buildBulletPoint(s, Icons.visibility)),
                    const SizedBox(height: 16),
                  ],

                  // Treatments
                  if (disease.organicTreatment.isNotEmpty) ...[
                    _buildSectionTitle('Organic Treatment'),
                    ...disease.organicTreatment.map((t) => _buildBulletPoint(t, Icons.nature)),
                    const SizedBox(height: 12),
                  ],
                  if (disease.chemicalTreatment.isNotEmpty) ...[
                    _buildSectionTitle('Chemical Treatment'),
                    ...disease.chemicalTreatment.map((t) => _buildBulletPoint(t, Icons.science)),
                    const SizedBox(height: 12),
                  ],

                  // Prevention
                  if (disease.prevention.isNotEmpty) ...[
                    _buildSectionTitle('Prevention'),
                    ...disease.prevention.map((p) => _buildBulletPoint(p, Icons.shield)),
                    const SizedBox(height: 12),
                  ],

                  // Warnings
                  if (disease.safetyWarnings.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              const Text('Safety Warnings', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...disease.safetyWarnings.map((w) => Text('• $w')),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
