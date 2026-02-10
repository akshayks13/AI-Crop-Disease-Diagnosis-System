import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/farm_provider.dart';

class FarmScreen extends ConsumerStatefulWidget {
  const FarmScreen({super.key});

  @override
  ConsumerState<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends ConsumerState<FarmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmState = ref.watch(farmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farm'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(farmProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Crops', icon: Icon(Icons.eco)),
            Tab(text: 'Tasks', icon: Icon(Icons.checklist)),
          ],
        ),
      ),
      body: farmState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : farmState.error != null
              ? _buildErrorWidget(farmState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCropsTab(farmState),
                    _buildTasksTab(farmState),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddCropDialog();
          } else {
            _showAddTaskDialog(farmState.crops);
          }
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCropsTab(FarmState farmState) {
    if (farmState.crops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No crops yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first crop to start tracking',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(farmProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: farmState.crops.length,
        itemBuilder: (context, index) {
          final crop = farmState.crops[index];
          return _buildCropCard(crop);
        },
      ),
    );
  }

  Widget _buildCropCard(FarmCrop crop) {
    // progress is now 0-100 from backend
    final progressFraction = (crop.progress / 100).clamp(0.0, 1.0);
    final progressPercent = crop.progress.toInt();

    return GestureDetector(
      onTap: () => _showEditCropDialog(crop),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_cropIcon(crop.cropType), color: Colors.green.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sown: ${crop.sowDateFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStageChip(crop.growthStage),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Growth Progress',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              if (crop.expectedHarvestDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Expected harvest: ${_formatDate(crop.expectedHarvestDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ],
              if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  crop.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Action row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditCropDialog(crop),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDeleteCrop(crop),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _cropIcon(String cropType) {
    final type = cropType.toLowerCase();
    if (type.contains('rice') || type.contains('wheat') || type.contains('corn') || type.contains('maize')) {
      return Icons.grass;
    }
    if (type.contains('tomato') || type.contains('potato') || type.contains('onion')) {
      return Icons.eco;
    }
    if (type.contains('cotton')) return Icons.cloud;
    return Icons.eco;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStageChip(String stage) {
    final stageColors = {
      'germination': Colors.brown,
      'seedling': Colors.lightGreen,
      'vegetative': Colors.green,
      'flowering': Colors.pink,
      'fruiting': Colors.orange,
      'ripening': Colors.amber,
      'harvest': Colors.teal,
    };

    final stageEmojis = {
      'germination': '🌱',
      'seedling': '🌿',
      'vegetative': '🍃',
      'flowering': '🌸',
      'fruiting': '🍅',
      'ripening': '🌾',
      'harvest': '🎉',
    };

    return Chip(
      avatar: Text(stageEmojis[stage] ?? '🌱', style: const TextStyle(fontSize: 14)),
      label: Text(
        stage.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: (stageColors[stage] ?? Colors.grey).withOpacity(0.2),
      labelStyle: TextStyle(color: stageColors[stage] ?? Colors.grey),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTasksTab(FarmState farmState) {
    final pendingTasks = farmState.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = farmState.tasks.where((t) => t.isCompleted).toList();

    if (farmState.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(farmProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingTasks.isNotEmpty) ...[
            Text(
              'Pending (${pendingTasks.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...pendingTasks.map((task) => _buildTaskTile(task)),
            const SizedBox(height: 16),
          ],
          if (completedTasks.isNotEmpty) ...[
            Text(
              'Completed (${completedTasks.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ...completedTasks.map((task) => _buildTaskTile(task)),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskTile(FarmTask task) {
    final priorityColors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green,
    };

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        ref.read(farmProvider.notifier).deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${task.title}" deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              ref.read(farmProvider.notifier).completeTask(task.id);
            },
            activeColor: Colors.green,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Row(
            children: [
              if (task.cropName != null) ...[
                Icon(Icons.eco, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(task.cropName!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 12),
              ],
              if (task.dueDate != null) ...[
                Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(task.dueDateFormatted, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ],
          ),
          trailing: Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColors[task.priority] ?? Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCropDialog() {
    final nameController = TextEditingController();
    final cropTypeController = TextEditingController();
    final notesController = TextEditingController();
    DateTime sowDate = DateTime.now();
    DateTime? harvestDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Crop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Crop Name',
                    hintText: 'e.g., Tomatoes - Field 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cropTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Crop Type',
                    hintText: 'e.g., Tomato',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Sow Date'),
                  subtitle: Text('${sowDate.day}/${sowDate.month}/${sowDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sowDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setDialogState(() => sowDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Expected Harvest Date'),
                  subtitle: Text(harvestDate != null
                      ? '${harvestDate!.day}/${harvestDate!.month}/${harvestDate!.year}'
                      : 'Not set (tap to set)'),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sowDate.add(const Duration(days: 90)),
                      firstDate: sowDate.add(const Duration(days: 1)),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => harvestDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g., Variety, fertilizer used',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && cropTypeController.text.isNotEmpty) {
                  final success = await ref.read(farmProvider.notifier).addCrop(
                    name: nameController.text,
                    cropType: cropTypeController.text,
                    sowDate: sowDate,
                    expectedHarvestDate: harvestDate,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Crop added!')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCropDialog(FarmCrop crop) {
    final notesController = TextEditingController(text: crop.notes ?? '');
    String selectedStage = crop.growthStage;
    bool isActive = crop.isActive;

    final stages = ['germination', 'seedling', 'vegetative', 'flowering', 'fruiting', 'ripening', 'harvest'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit: ${crop.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Growth stage selector
                DropdownButtonFormField<String>(
                  value: selectedStage,
                  decoration: const InputDecoration(
                    labelText: 'Growth Stage',
                    border: OutlineInputBorder(),
                  ),
                  items: stages.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('${_stageEmoji(s)} ${s[0].toUpperCase()}${s.substring(1)}'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedStage = val!),
                ),
                const SizedBox(height: 12),
                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                // Active toggle
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: Text(isActive ? 'Crop is being tracked' : 'Crop is archived'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{};
                if (selectedStage != crop.growthStage) data['growth_stage'] = selectedStage;
                if (notesController.text != (crop.notes ?? '')) data['notes'] = notesController.text;
                if (isActive != crop.isActive) data['is_active'] = isActive;

                if (data.isNotEmpty) {
                  await ref.read(farmProvider.notifier).updateCrop(crop.id, data);
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crop updated!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _stageEmoji(String stage) {
    const emojis = {
      'germination': '🌱',
      'seedling': '🌿',
      'vegetative': '🍃',
      'flowering': '🌸',
      'fruiting': '🍅',
      'ripening': '🌾',
      'harvest': '🎉',
    };
    return emojis[stage] ?? '🌱';
  }

  void _confirmDeleteCrop(FarmCrop crop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Crop'),
        content: Text('Delete "${crop.displayName}" and all its tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(farmProvider.notifier).deleteCrop(crop.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${crop.displayName}" deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(List<FarmCrop> crops) {
    final titleController = TextEditingController();
    String? selectedCropId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g., Water the plants',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCropId,
                  decoration: const InputDecoration(
                    labelText: 'Related Crop (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No specific crop')),
                    ...crops.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.displayName),
                    )),
                  ],
                  onChanged: (val) => setDialogState(() => selectedCropId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final success = await ref.read(farmProvider.notifier).addTask(
                    title: titleController.text,
                    cropId: selectedCropId,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task added!')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Failed to load farm data'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(farmProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
