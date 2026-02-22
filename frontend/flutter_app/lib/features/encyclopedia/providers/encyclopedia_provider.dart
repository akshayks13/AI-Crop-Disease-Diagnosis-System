import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Crop encyclopedia entry model
class CropInfo {
  final String id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? season;
  final double? tempMin;
  final double? tempMax;
  final String? waterRequirement;
  final String? soilType;
  final List<String> growingTips;
  final List<String> commonDiseases;
  final String? imageUrl;

  CropInfo({
    required this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.season,
    this.tempMin,
    this.tempMax,
    this.waterRequirement,
    this.soilType,
    this.growingTips = const [],
    this.commonDiseases = const [],
    this.imageUrl,
  });

  factory CropInfo.fromJson(Map<String, dynamic> json) {
    return CropInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientific_name'],
      description: json['description'],
      season: json['season'],
      tempMin: (json['temp_min'] as num?)?.toDouble(),
      tempMax: (json['temp_max'] as num?)?.toDouble(),
      waterRequirement: json['water_requirement'],
      soilType: json['soil_type'],
      growingTips: (json['growing_tips'] as List?)?.cast<String>() ?? [],
      commonDiseases: (json['common_diseases'] as List?)?.cast<String>() ?? [],
      imageUrl: json['image_url'],
    );
  }

  String get temperatureRange {
    if (tempMin != null && tempMax != null) {
      return '${tempMin!.toInt()}°C - ${tempMax!.toInt()}°C';
    }
    return 'N/A';
  }
}

/// Disease encyclopedia entry model
class DiseaseInfo {
  final String id;
  final String name;
  final String? scientificName;
  final List<String> affectedCrops;
  final String? description;
  final List<String> symptoms;
  final String? causes;
  final List<String> chemicalTreatment;
  final List<String> organicTreatment;
  final List<String> prevention;
  final String? severityLevel;
  final List<String> safetyWarnings;
  final String? imageUrl;

  DiseaseInfo({
    required this.id,
    required this.name,
    this.scientificName,
    this.affectedCrops = const [],
    this.description,
    this.symptoms = const [],
    this.causes,
    this.chemicalTreatment = const [],
    this.organicTreatment = const [],
    this.prevention = const [],
    this.severityLevel,
    this.safetyWarnings = const [],
    this.imageUrl,
  });

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientific_name'],
      affectedCrops: (json['affected_crops'] as List?)?.cast<String>() ?? [],
      description: json['description'],
      symptoms: (json['symptoms'] as List?)?.cast<String>() ?? [],
      causes: json['causes'],
      chemicalTreatment: (json['chemical_treatment'] as List?)?.cast<String>() ?? [],
      organicTreatment: (json['organic_treatment'] as List?)?.cast<String>() ?? [],
      prevention: (json['prevention'] as List?)?.cast<String>() ?? [],
      severityLevel: json['severity_level'],
      safetyWarnings: (json['safety_warnings'] as List?)?.cast<String>() ?? [],
      imageUrl: json['image_url'],
    );
  }
}

/// Pest encyclopedia entry model
class PestInfo {
  final String id;
  final String name;
  final String? scientificName;
  final List<String> affectedCrops;
  final String? description;
  final List<String> symptoms;
  final String? appearance;
  final String? damageType;
  final String? lifeCycle;
  final List<String> controlMethods;
  final List<String> organicControl;
  final List<String> chemicalControl;
  final List<String> prevention;
  final String? severityLevel;
  final String? imageUrl;

  PestInfo({
    required this.id,
    required this.name,
    this.scientificName,
    this.affectedCrops = const [],
    this.description,
    this.symptoms = const [],
    this.appearance,
    this.damageType,
    this.lifeCycle,
    this.controlMethods = const [],
    this.organicControl = const [],
    this.chemicalControl = const [],
    this.prevention = const [],
    this.severityLevel,
    this.imageUrl,
  });

  factory PestInfo.fromJson(Map<String, dynamic> json) {
    return PestInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientific_name'],
      affectedCrops: (json['affected_crops'] as List?)?.cast<String>() ?? [],
      description: json['description'],
      symptoms: (json['symptoms'] as List?)?.cast<String>() ?? [],
      appearance: json['appearance'],
      damageType: json['damage_type'],
      lifeCycle: json['life_cycle'],
      controlMethods: (json['control_methods'] as List?)?.cast<String>() ?? [],
      organicControl: (json['organic_control'] as List?)?.cast<String>() ?? [],
      chemicalControl: (json['chemical_control'] as List?)?.cast<String>() ?? [],
      prevention: (json['prevention'] as List?)?.cast<String>() ?? [],
      severityLevel: json['severity_level'],
      imageUrl: json['image_url'],
    );
  }
}

/// Encyclopedia state
class EncyclopediaState {
  final List<CropInfo> crops;
  final List<DiseaseInfo> diseases;
  final List<PestInfo> pests;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  EncyclopediaState({
    this.crops = const [],
    this.diseases = const [],
    this.pests = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  EncyclopediaState copyWith({
    List<CropInfo>? crops,
    List<DiseaseInfo>? diseases,
    List<PestInfo>? pests,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return EncyclopediaState(
      crops: crops ?? this.crops,
      diseases: diseases ?? this.diseases,
      pests: pests ?? this.pests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<CropInfo> get filteredCrops {
    if (searchQuery == null || searchQuery!.isEmpty) return crops;
    final query = searchQuery!.toLowerCase();
    return crops.where((c) => 
      c.name.toLowerCase().contains(query) ||
      (c.scientificName?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  List<DiseaseInfo> get filteredDiseases {
    if (searchQuery == null || searchQuery!.isEmpty) return diseases;
    final query = searchQuery!.toLowerCase();
    return diseases.where((d) => 
      d.name.toLowerCase().contains(query) ||
      d.affectedCrops.any((c) => c.toLowerCase().contains(query))
    ).toList();
  }

  List<PestInfo> get filteredPests {
    if (searchQuery == null || searchQuery!.isEmpty) return pests;
    final query = searchQuery!.toLowerCase();
    return pests.where((p) =>
      p.name.toLowerCase().contains(query) ||
      (p.scientificName?.toLowerCase().contains(query) ?? false) ||
      p.affectedCrops.any((c) => c.toLowerCase().contains(query))
    ).toList();
  }
}

/// Encyclopedia notifier
class EncyclopediaNotifier extends StateNotifier<EncyclopediaState> {
  final ApiClient _api;

  EncyclopediaNotifier(this._api) : super(EncyclopediaState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final cropsResponse = await _api.get(ApiConfig.encyclopediaCrops);
      final diseasesResponse = await _api.get(ApiConfig.encyclopediaDiseases);
      final pestsResponse = await _api.get('/encyclopedia/pests');
      
      final cropsData = cropsResponse.data as Map<String, dynamic>;
      final diseasesData = diseasesResponse.data as Map<String, dynamic>;
      final pestsData = pestsResponse.data as Map<String, dynamic>;
      
      final cropsList = (cropsData['crops'] as List)
          .map((c) => CropInfo.fromJson(c))
          .toList();
      final diseasesList = (diseasesData['diseases'] as List)
          .map((d) => DiseaseInfo.fromJson(d))
          .toList();
      final pestsList = (pestsData['pests'] as List)
          .map((p) => PestInfo.fromJson(p))
          .toList();
      
      state = state.copyWith(
        crops: cropsList,
        diseases: diseasesList,
        pests: pestsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  CropInfo? getCropByName(String name) {
    try {
      return state.crops.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<DiseaseInfo> getDiseasesForCrop(String cropName) {
    return state.diseases.where(
      (d) => d.affectedCrops.any((c) => c.toLowerCase() == cropName.toLowerCase())
    ).toList();
  }

  Future<void> refresh() => loadData();
}

/// Provider for encyclopedia data
final encyclopediaProvider = StateNotifierProvider<EncyclopediaNotifier, EncyclopediaState>((ref) {
  final api = ref.watch(apiClientProvider);
  return EncyclopediaNotifier(api);
});
