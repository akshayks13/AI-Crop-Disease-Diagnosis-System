import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farm Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            tooltip: 'Ask AI',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Active Crops', 
                    '3', 
                    AppTheme.primaryGreen, 
                    Icons.grass,
                    theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Pending Tasks', 
                    '5', 
                    AppTheme.accentOrange, 
                    Icons.assignment_late_outlined,
                    theme,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Your Crops Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Crops',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCropCard(
              'Field 1 - Tomatoes',
              'Sown: 15 Jan 2026',
              0.2,
              'Vegetative',
              'Next: Apply Fertilizer (2 days)',
              theme,
            ),
            _buildCropCard(
              'Field 2 - Potatoes',
              'Sown: 10 Dec 2025',
              0.6,
              'Tuber Formation',
              'Next: Irrigation (Tomorrow)',
              theme,
            ),
             _buildCropCard(
              'Backyard - Chillies',
              'Sown: 01 Feb 2026',
              0.05,
              'Germination',
              'Next: Check Moisture',
              theme,
            ),
            
            const SizedBox(height: 24),
            
            // Upcoming Tasks
            Text(
              'Upcoming Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTaskItem('Water Tomato Field', 'Tomorrow, 6:00 AM', true, theme),
                  _buildTaskItem('Apply Nitrogen to Potato', '3 Feb, 8:00 AM', false, theme),
                  _buildTaskItem('Scout for Pests (Weekly)', '4 Feb, 9:00 AM', false, theme),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show a simple dialog for now
          showDialog(
            context: context, 
            builder: (ctx) => AlertDialog(
              title: const Text('Add New Crop'),
              content: const Text('Crop addition form will be available in the next update.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        },
        label: const Text('Add Crop'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(String title, String subtitle, double progress, String stage, String nextTask, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primaryGreen,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event_note, size: 16, color: AppTheme.accentOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextTask,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String time, bool isDone, ThemeData theme) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: isDone ? null : Border.all(color: Colors.grey.shade400),
              ),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: 16,
                color: isDone ? AppTheme.primaryGreen : Colors.transparent,
              ),
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: isDone ? TextDecoration.lineThrough : null,
              // Explicitly set color for unfinished tasks to black87 to ensure visibility
              color: isDone ? Colors.grey : Colors.black87,
              fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            time,
            style: TextStyle(
              color: isDone ? Colors.grey.shade400 : AppTheme.accentOrange,
              fontSize: 12,
            ),
          ),
        ),
        if (title != 'Scout for Pests (Weekly)') 
          const Divider(height: 1, indent: 70),
      ],
    );
  }
}
