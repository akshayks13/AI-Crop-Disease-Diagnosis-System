import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Expert Dashboard screen
class ExpertDashboardScreen extends ConsumerWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPending = user?.isPendingExpert ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, AppRoutes.profile)),
        ],
      ),
      body: isPending ? _PendingApprovalView() : const _ApprovedExpertView(),
    );
  }
}

class _PendingApprovalView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.hourglass_empty, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Application Under Review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Your expert application is being reviewed by our team. You will be notified once approved.',
                textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _ApprovedExpertView extends ConsumerStatefulWidget {
  const _ApprovedExpertView();

  @override
  ConsumerState<_ApprovedExpertView> createState() => _ApprovedExpertViewState();
}

class _ApprovedExpertViewState extends ConsumerState<_ApprovedExpertView> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(ApiConfig.expertStats);
      if (mounted) {
        setState(() {
          _stats = response.data;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Stats or defaults
    final totalAnswers = _stats?['total_answers'] ?? '-';
    final avgRating = _stats?['average_rating']?.toString() ?? '-';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome & Stats Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, color: theme.colorScheme.onPrimary, size: 28),
                    const SizedBox(width: 12),
                    Text('Expert Panel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(totalAnswers.toString(), 'Answred'),
                    Container(width: 1, height: 40, color: theme.colorScheme.onPrimary.withOpacity(0.24)),
                    _buildStatItem(avgRating, 'Avg Rating'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
          const SizedBox(height: 16),

          // Grid Layout
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _ActionCard(
                icon: Icons.question_answer_rounded,
                title: 'Open Questions',
                count: 'Answer New',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expertQuestions),
              ),
              _ActionCard(
                icon: Icons.history_edu_rounded,
                title: 'My History',
                count: 'View Past',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expertMyAnswers),
              ),
              _ActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Knowledge Base',
                count: 'Guides',
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expertKnowledgeBase),
              ),
              _ActionCard(
                icon: Icons.trending_up_rounded,
                title: 'Trending',
                count: 'Top Diseases',
                color: Colors.red,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expertTrending),
              ),
              _ActionCard(
                icon: Icons.article_rounded,
                title: 'Community',
                count: 'Post Tips',
                color: Colors.amber,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expertCommunity),
              ),
              _ActionCard(
                icon: Icons.analytics_rounded,
                title: 'Statistics',
                count: 'Performance',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expertStats),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.7), fontSize: 13)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(count, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
