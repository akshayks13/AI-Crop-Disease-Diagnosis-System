/// Disease classification labels from TFLite model
/// Format: plant_disease (e.g., 'apple_black_rot' -> plant: 'Apple', disease: 'Black Rot')
const List<String> diseaseLabels = [
  'apple_apple_scab',
  'apple_black_rot',
  'apple_cedar_apple_rust',
  'bean_angular_leaf_spot',
  'bean_rust',
  'bell_pepper_bacterial_spot',
  'cherry_powdery_mildew',
  'corn_cercospora_leaf_spot',
  'corn_common_rust',
  'corn_gray_leaf_spot',
  'corn_northern_leaf_blight',
  'cotton_aphids',
  'cotton_army_worm',
  'cotton_bacterial_blight',
  'cotton_powdery_mildew',
  'cotton_target_spot',
  'diseased_cucumber',
  'diseased_rice',
  'grape_black_rot',
  'grape_esca_black_measles',
  'grape_leaf_blight',
  'groundnut_early_leaf_spot',
  'groundnut_late_leaf_spot',
  'groundnut_nutrition_deficiency',
  'groundnut_rust',
  'guava_anthracnose',
  'guava_fruit_fly',
  'healthy_apple',
  'healthy_bean',
  'healthy_bell_pepper',
  'healthy_cherry',
  'healthy_corn',
  'healthy_cotton',
  'healthy_cucumber',
  'healthy_grape',
  'healthy_groundnut',
  'healthy_guava',
  'healthy_lemon',
  'healthy_peach',
  'healthy_potato',
  'healthy_pumpkin',
  'healthy_rice',
  'healthy_strawberry',
  'healthy_sugarcane',
  'healthy_tomato',
  'healthy_wheat',
  'lemon_anthracnose',
  'lemon_bacterial_blight',
  'lemon_citrus_canker',
  'lemon_curl_virus',
  'lemon_deficiency',
  'lemon_dry_leaf',
  'lemon_sooty_mould',
  'lemon_spider_mites',
  'peach_bacterial_spot',
  'potato_early_blight',
  'potato_late_blight',
  'pumpkin_bacterial_leaf_spot',
  'pumpkin_downy_mildew',
  'pumpkin_mosaic_disease',
  'pumpkin_powdery_mildew',
  'strawberry_leaf_scorch',
  'sugarcane_bacterial_blight',
  'sugarcane_mosaic',
  'sugarcane_red_rot',
  'sugarcane_rust',
  'sugarcane_yellow_leaf_disease',
  'tomato_bacterial_spot',
  'tomato_early_blight',
  'tomato_late_blight',
  'tomato_septoria_leaf_spot',
  'tomato_yellow_leaf_curl_virus',
  'wheat_aphid',
  'wheat_black_rust',
  'wheat_blast',
  'wheat_brown_rust',
  'wheat_common_root_rot',
  'wheat_fusarium_head_blight',
  'wheat_leaf_blight',
  'wheat_mildew',
  'wheat_mite',
  'wheat_septoria',
  'wheat_smut',
  'wheat_stem_fly',
  'wheat_tan_spot',
  'wheat_yellow_rust',
];

/// Parse label to extract plant name and disease
class DiseaseInfo {
  final String plant;
  final String disease;
  final bool isHealthy;

  DiseaseInfo({required this.plant, required this.disease, required this.isHealthy});

  /// Parse a label like 'apple_black_rot' or 'healthy_apple'
  factory DiseaseInfo.fromLabel(String label) {
    final parts = label.split('_');
    
    if (parts.isNotEmpty && parts[0] == 'healthy') {
      // Format: healthy_plantname
      final plant = parts.sublist(1).join(' ');
      return DiseaseInfo(
        plant: _capitalize(plant),
        disease: 'Healthy',
        isHealthy: true,
      );
    } else if (parts.isNotEmpty && parts[0] == 'diseased') {
      // Format: diseased_plantname
      final plant = parts.sublist(1).join(' ');
      return DiseaseInfo(
        plant: _capitalize(plant),
        disease: 'Diseased (Unknown)',
        isHealthy: false,
      );
    } else if (parts.length >= 2) {
      // Format: plant_disease_name
      final plant = parts[0];
      final disease = parts.sublist(1).join(' ');
      return DiseaseInfo(
        plant: _capitalize(plant),
        disease: _capitalize(disease),
        isHealthy: false,
      );
    }
    
    return DiseaseInfo(plant: 'Unknown', disease: label, isHealthy: false);
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
