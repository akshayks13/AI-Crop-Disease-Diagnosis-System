import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Farm crop model
class FarmCrop {
  final String id;
  final String name;
  final String cropType;
  final String? fieldName;
  final double? areaSize;
  final String areaUnit;
  final DateTime sowDate;
  final DateTime? expectedHarvestDate;
  final String growthStage;
  final double progress;
  final String? notes;
  final bool isActive;

  FarmCrop({
    required this.id,
    required this.name,
    required this.cropType,
    this.fieldName,
    this.areaSize,
    required this.areaUnit,
    required this.sowDate,
    this.expectedHarvestDate,
    required this.growthStage,
    required this.progress,
    this.notes,
    required this.isActive,
  });

  factory FarmCrop.fromJson(Map<String, dynamic> json) {
    return FarmCrop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cropType: json['crop_type'] ?? '',
      fieldName: json['field_name'],
      areaSize: (json['area_size'] as num?)?.toDouble(),
      areaUnit: json['area_unit'] ?? 'acres',
      sowDate: json['sow_date'] != null 
          ? DateTime.parse(json['sow_date']) 
          : DateTime.now(),
      expectedHarvestDate: json['expected_harvest_date'] != null 
          ? DateTime.parse(json['expected_harvest_date']) 
          : null,
      growthStage: json['growth_stage'] ?? 'germination',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
    );
  }

  String get displayName => fieldName != null ? '$fieldName - $cropType' : name;
  
  String get sowDateFormatted {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${sowDate.day} ${months[sowDate.month - 1]} ${sowDate.year}';
  }
}

/// Farm task model
class FarmTask {
  final String id;
  final String title;
  final String? description;
  final String? cropId;
  final String? cropName;
  final DateTime? dueDate;
  final String priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isRecurring;
  final int? recurrenceDays;

  FarmTask({
    required this.id,
    required this.title,
    this.description,
    this.cropId,
    this.cropName,
    this.dueDate,
    required this.priority,
    required this.isCompleted,
    this.completedAt,
    required this.isRecurring,
    this.recurrenceDays,
  });

  factory FarmTask.fromJson(Map<String, dynamic> json) {
    return FarmTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      cropId: json['crop_id'],
      cropName: json['crop_name'],
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) 
          : null,
      priority: json['priority'] ?? 'medium',
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      isRecurring: json['is_recurring'] ?? false,
      recurrenceDays: json['recurrence_days'],
    );
  }

  String get dueDateFormatted {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final diff = dueDate!.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return '${dueDate!.day}/${dueDate!.month}';
  }
}

/// Farm state
class FarmState {
  final List<FarmCrop> crops;
  final List<FarmTask> tasks;
  final bool isLoading;
  final String? error;

  FarmState({
    this.crops = const [],
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  FarmState copyWith({
    List<FarmCrop>? crops,
    List<FarmTask>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return FarmState(
      crops: crops ?? this.crops,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get activeCropsCount => crops.where((c) => c.isActive).length;
  int get pendingTasksCount => tasks.where((t) => !t.isCompleted).length;
  List<FarmTask> get upcomingTasks => tasks.where((t) => !t.isCompleted).take(5).toList();
}

/// Farm notifier
class FarmNotifier extends StateNotifier<FarmState> {
  final ApiClient _api;

  FarmNotifier(this._api) : super(FarmState()) {
    loadFarmData();
  }

  Future<void> loadFarmData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final cropsResponse = await _api.get(ApiConfig.farmCrops);
      final tasksResponse = await _api.get(ApiConfig.farmTasks);
      
      final cropsData = cropsResponse.data as Map<String, dynamic>;
      final tasksData = tasksResponse.data as Map<String, dynamic>;
      
      final cropsList = (cropsData['crops'] as List)
          .map((c) => FarmCrop.fromJson(c))
          .toList();
      final tasksList = (tasksData['tasks'] as List)
          .map((t) => FarmTask.fromJson(t))
          .toList();
      
      state = state.copyWith(
        crops: cropsList,
        tasks: tasksList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCrop({
    required String name,
    required String cropType,
    String? fieldName,
    double? areaSize,
    required DateTime sowDate,
    DateTime? expectedHarvestDate,
  }) async {
    try {
      await _api.post(
        ApiConfig.farmCrops,
        data: {
          'name': name,
          'crop_type': cropType,
          if (fieldName != null) 'field_name': fieldName,
          if (areaSize != null) 'area_size': areaSize,
          'sow_date': sowDate.toIso8601String().split('T')[0],
          if (expectedHarvestDate != null) 
            'expected_harvest_date': expectedHarvestDate.toIso8601String().split('T')[0],
        },
      );
      await loadFarmData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addTask({
    required String title,
    String? description,
    String? cropId,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    try {
      await _api.post(
        ApiConfig.farmTasks,
        data: {
          'title': title,
          if (description != null) 'description': description,
          if (cropId != null) 'crop_id': cropId,
          if (dueDate != null) 'due_date': dueDate.toIso8601String(),
          'priority': priority,
        },
      );
      await loadFarmData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      await _api.put('${ApiConfig.farmTasks}/$taskId/complete');
      await loadFarmData();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCrop(String cropId) async {
    try {
      await _api.delete('${ApiConfig.farmCrops}/$cropId');
      await loadFarmData();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> refresh() => loadFarmData();
}

/// Provider for farm data
final farmProvider = StateNotifierProvider<FarmNotifier, FarmState>((ref) {
  final api = ref.watch(apiClientProvider);
  return FarmNotifier(api);
});
