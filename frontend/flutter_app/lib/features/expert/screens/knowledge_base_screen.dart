import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Knowledge Base Screen - Manage agronomy rules and treatment guides
class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _diagnosticRules = [];
  List<Map<String, dynamic>> _treatmentConstraints = [];
  List<Map<String, dynamic>> _seasonalPatterns = [];
  List<Map<String, dynamic>> _crops = [];
  List<Map<String, dynamic>> _diseases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      
      final results = await Future.wait([
        api.get('/agronomy/diagnostic-rules'),
        api.get('/agronomy/treatment-constraints'),
        api.get('/agronomy/seasonal-patterns'),
        api.get('/encyclopedia/crops'),
        api.get('/encyclopedia/diseases'),
      ]);
      
      if (mounted) {
        setState(() {
          _diagnosticRules = List<Map<String, dynamic>>.from(results[0].data['rules'] ?? []);
          _treatmentConstraints = List<Map<String, dynamic>>.from(results[1].data['constraints'] ?? []);
          _seasonalPatterns = List<Map<String, dynamic>>.from(results[2].data['patterns'] ?? []);
          _crops = List<Map<String, dynamic>>.from(results[3].data['crops'] ?? []);
          _diseases = List<Map<String, dynamic>>.from(results[4].data['diseases'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.rule), text: 'Diagnostic Rules'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Constraints'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Seasonal'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiagnosticRulesTab(theme),
                _buildConstraintsTab(theme),
                _buildSeasonalTab(theme),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      _showCreateRuleDialog();
    } else if (currentTab == 1) {
      _showCreateConstraintDialog();
    } else {
      _showCreatePatternDialog();
    }
  }

  void _showCreateRuleDialog() {
    final ruleNameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedDiseaseId;
    final priorityCtrl = TextEditingController(text: '1.0');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Diagnostic Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ruleNameCtrl, decoration: const InputDecoration(labelText: 'Rule Name*')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedDiseaseId,
                  decoration: const InputDecoration(labelText: 'Disease*'),
                  items: _diseases.map((d) => DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text(d['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedDiseaseId = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 8),
                TextField(controller: priorityCtrl, decoration: const InputDecoration(labelText: 'Priority'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (ruleNameCtrl.text.isEmpty || selectedDiseaseId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                  return;
                }
                try {
                  final api = ref.read(apiClientProvider);
                  await api.post('/agronomy/diagnostic-rules', data: {
                    'rule_name': ruleNameCtrl.text,
                    'description': descCtrl.text,
                    'disease_id': selectedDiseaseId,
                    'conditions': {},
                    'impact': {},
                    'priority': double.tryParse(priorityCtrl.text) ?? 1.0,
                    'is_active': true,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule created!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateConstraintDialog() {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'chemical');
    final descCtrl = TextEditingController();
    String riskLevel = 'medium';
    String enforcementLevel = 'warn';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Treatment Constraint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Treatment Name*')),
                const SizedBox(height: 8),
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (chemical/organic)*')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description*'), maxLines: 3),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: riskLevel,
                  decoration: const InputDecoration(labelText: 'Risk Level'),
                  items: ['low', 'medium', 'high', 'critical'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => riskLevel = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: enforcementLevel,
                  decoration: const InputDecoration(labelText: 'Enforcement'),
                  items: ['warn', 'block', 'requires_approval'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => enforcementLevel = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || typeCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                  return;
                }
                try {
                  final api = ref.read(apiClientProvider);
                  await api.post('/agronomy/treatment-constraints', data: {
                    'treatment_name': nameCtrl.text,
                    'treatment_type': typeCtrl.text,
                    'constraint_description': descCtrl.text,
                    'restricted_conditions': {},
                    'enforcement_level': enforcementLevel,
                    'risk_level': riskLevel,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Constraint created!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePatternDialog() {
    String? selectedDiseaseId;
    String? selectedCropId;
    final regionCtrl = TextEditingController();
    String season = 'Kharif';
    final likelihoodCtrl = TextEditingController(text: '0.5');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Seasonal Pattern'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDiseaseId,
                  decoration: const InputDecoration(labelText: 'Disease*'),
                  items: _diseases.map((d) => DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text(d['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedDiseaseId = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCropId,
                  decoration: const InputDecoration(labelText: 'Crop*'),
                  items: _crops.map((c) => DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(c['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCropId = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: season,
                  decoration: const InputDecoration(labelText: 'Season'),
                  items: ['Kharif', 'Rabi', 'Zaid', 'All Year'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => season = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: regionCtrl, decoration: const InputDecoration(labelText: 'Region (optional)')),
                const SizedBox(height: 8),
                TextField(
                  controller: likelihoodCtrl,
                  decoration: const InputDecoration(labelText: 'Likelihood (0.0-1.0)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDiseaseId == null || selectedCropId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                  return;
                }
                try {
                  final api = ref.read(apiClientProvider);
                  await api.post('/agronomy/seasonal-patterns', data: {
                    'disease_id': selectedDiseaseId,
                    'crop_id': selectedCropId,
                    'season': season,
                    'region': regionCtrl.text.isEmpty ? null : regionCtrl.text,
                    'likelihood_score': double.tryParse(likelihoodCtrl.text) ?? 0.5,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pattern created!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    final ruleNameCtrl = TextEditingController(text: rule['rule_name']);
    final descCtrl = TextEditingController(text: rule['description']);
    String? selectedDiseaseId = rule['disease_id']?.toString();
    final priorityCtrl = TextEditingController(text: rule['priority']?.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Diagnostic Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ruleNameCtrl, decoration: const InputDecoration(labelText: 'Rule Name*')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedDiseaseId,
                  decoration: const InputDecoration(labelText: 'Disease*'),
                  items: _diseases.map((d) => DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text(d['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedDiseaseId = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 8),
                TextField(controller: priorityCtrl, decoration: const InputDecoration(labelText: 'Priority'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (ruleNameCtrl.text.isEmpty || selectedDiseaseId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                  return;
                }
                try {
                  final api = ref.read(apiClientProvider);
                  await api.put('/agronomy/diagnostic-rules/${rule['id']}', data: {
                    'rule_name': ruleNameCtrl.text,
                    'description': descCtrl.text,
                    'disease_id': selectedDiseaseId,
                    'priority': double.tryParse(priorityCtrl.text) ?? 1.0,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule updated!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditConstraintDialog(Map<String, dynamic> constraint) {
    final nameCtrl = TextEditingController(text: constraint['treatment_name']);
    final typeCtrl = TextEditingController(text: constraint['treatment_type']);
    final descCtrl = TextEditingController(text: constraint['constraint_description']);
    String riskLevel = constraint['risk_level'] ?? 'medium';
    String enforcementLevel = constraint['enforcement_level'] ?? 'warn';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Treatment Constraint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Treatment Name*')),
                const SizedBox(height: 8),
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (chemical/organic)*')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description*'), maxLines: 3),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: riskLevel,
                  decoration: const InputDecoration(labelText: 'Risk Level'),
                  items: ['low', 'medium', 'high', 'critical'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => riskLevel = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: enforcementLevel,
                  decoration: const InputDecoration(labelText: 'Enforcement'),
                  items: ['warn', 'block', 'requires_approval'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => enforcementLevel = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || typeCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                  return;
                }
                try {
                  final api = ref.read(apiClientProvider);
                  await api.put('/agronomy/treatment-constraints/${constraint['id']}', data: {
                    'treatment_name': nameCtrl.text,
                    'treatment_type': typeCtrl.text,
                    'constraint_description': descCtrl.text,
                    'enforcement_level': enforcementLevel,
                    'risk_level': riskLevel,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Constraint updated!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPatternDialog(Map<String, dynamic> pattern) {
    String? selectedDiseaseId = pattern['disease_id']?.toString();
    String? selectedCropId = pattern['crop_id']?.toString();
    final regionCtrl = TextEditingController(text: pattern['region']);
    String season = pattern['season'] ?? 'Kharif';
    final likelihoodCtrl = TextEditingController(text: pattern['likelihood_score']?.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Seasonal Pattern'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDiseaseId,
                  decoration: const InputDecoration(labelText: 'Disease*'),
                  items: _diseases.map((d) => DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text(d['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedDiseaseId = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCropId,
                  decoration: const InputDecoration(labelText: 'Crop*'),
                  items: _crops.map((c) => DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(c['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCropId = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: season,
                  decoration: const InputDecoration(labelText: 'Season'),
                  items: ['Kharif', 'Rabi', 'Zaid', 'All Year'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => season = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: regionCtrl, decoration: const InputDecoration(labelText: 'Region (optional)')),
                const SizedBox(height: 8),
                TextField(
                  controller: likelihoodCtrl,
                  decoration: const InputDecoration(labelText: 'Likelihood (0.0-1.0)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDiseaseId == null || selectedCropId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
                  return;
                }
                try {
                  final api = ref.read(apiClientProvider);
                  await api.put('/agronomy/seasonal-patterns/${pattern['id']}', data: {
                    'disease_id': selectedDiseaseId,
                    'crop_id': selectedCropId,
                    'season': season,
                    'region': regionCtrl.text.isEmpty ? null : regionCtrl.text,
                    'likelihood_score': double.tryParse(likelihoodCtrl.text) ?? 0.5,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pattern updated!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('/agronomy/diagnostic-rules/$id');
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteConstraint(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Constraint?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('/agronomy/treatment-constraints/$id');
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deletePattern(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pattern?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.delete('/agronomy/seasonal-patterns/$id');
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildDiagnosticRulesTab(ThemeData theme) {
    if (_diagnosticRules.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rule,
        title: 'No Diagnostic Rules',
        subtitle: 'Tap + to add your first diagnostic rule.',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _diagnosticRules.length,
        itemBuilder: (context, index) {
          final rule = _diagnosticRules[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science, color: Colors.blue),
              ),
              title: Text(rule['rule_name'] ?? 'Unnamed Rule', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Disease: ${rule['disease_name'] ?? 'Unknown'}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditRuleDialog(rule),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRule(rule['id']),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rule['description'] != null) ...[
                        Text(rule['description'], style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Chip(label: Text('Priority: ${rule['priority'] ?? 1.0}'), backgroundColor: Colors.orange.withOpacity(0.1)),
                          const SizedBox(width: 8),
                          if (rule['is_active'] == true)
                            const Chip(label: Text('Active'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConstraintsTab(ThemeData theme) {
    if (_treatmentConstraints.isEmpty) {
      return _buildEmptyState(
        icon: Icons.warning_amber,
        title: 'No Treatment Constraints',
        subtitle: 'Tap + to add safety constraints.',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _treatmentConstraints.length,
        itemBuilder: (context, index) {
          final constraint = _treatmentConstraints[index];
          final riskLevel = constraint['risk_level'] ?? 'medium';
          final riskColor = _getRiskColor(riskLevel);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning, color: riskColor),
              ),
              title: Text(constraint['treatment_name'] ?? 'Unknown Treatment', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(riskLevel.toUpperCase(), style: TextStyle(fontSize: 10, color: riskColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(constraint['treatment_type'] ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditConstraintDialog(constraint),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteConstraint(constraint['id']),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(constraint['constraint_description'] ?? '', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Chip(label: Text('Enforcement: ${constraint['enforcement_level'] ?? 'warn'}'), backgroundColor: Colors.purple.withOpacity(0.1)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeasonalTab(ThemeData theme) {
    if (_seasonalPatterns.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_month,
        title: 'No Seasonal Patterns',
        subtitle: 'Tap + to add seasonal disease patterns.',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _seasonalPatterns.length,
        itemBuilder: (context, index) {
          final pattern = _seasonalPatterns[index];
          final likelihood = (pattern['likelihood_score'] ?? 0.5) as double;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getSeasonColor(pattern['season']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getSeasonIcon(pattern['season']), color: _getSeasonColor(pattern['season'])),
              ),
              title: Text('${pattern['disease_name'] ?? 'Unknown'} on ${pattern['crop_name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${pattern['season']} ${pattern['region'] != null ? "• ${pattern['region']}" : ""}'),
                  const SizedBox(height: 8),
                  Text('Likelihood: ${(likelihood * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditPatternDialog(pattern),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePattern(pattern['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.deepOrange;
      case 'critical': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getSeasonColor(String? season) {
    switch (season?.toLowerCase()) {
      case 'kharif': return Colors.green;
      case 'rabi': return Colors.blue;
      case 'zaid': return Colors.orange;
      default: return Colors.purple;
    }
  }

  IconData _getSeasonIcon(String? season) {
    switch (season?.toLowerCase()) {
      case 'kharif': return Icons.water_drop;
      case 'rabi': return Icons.ac_unit;
      case 'zaid': return Icons.wb_sunny;
      default: return Icons.calendar_today;
    }
  }
}
