import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/auth_provider.dart';

/// Home screen for Farmer users
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Diagnosis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // extra bottom padding for floating action button
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreen.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.fullName.split(' ').first ?? 'Farmer'}! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Protect your crops with AI-powered disease detection',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Main action cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // lower aspect ratio so that cards get a bit more vertical room
                childAspectRatio: 0.9,
                children: [
                  _ActionCard(
                    title: 'Diagnose\nCrop',
                    subtitle: 'Take a photo',
                    icon: Icons.camera_alt,
                    color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.diagnosis),
                  ),
                  _ActionCard(
                    title: 'Ask\nExpert',
                    subtitle: 'Get advice',
                    icon: Icons.support_agent,
                    color: const Color(0xFFFF9800),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.askExpert),
                  ),
                  _ActionCard(
                    title: 'Weather\nForecast',
                    subtitle: 'Track rain & sun',
                    icon: Icons.wb_sunny,
                    color: const Color(0xFF2196F3), 
                    onTap: () => Navigator.pushNamed(context, AppRoutes.weather),
                  ),
                  _ActionCard(
                    title: 'Market\nPrices',
                    subtitle: 'Live rates',
                    icon: Icons.currency_rupee,
                    color: const Color(0xFFE91E63),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.market),
                  ),
                  _ActionCard(
                    title: 'Farming\nCommunity',
                    subtitle: 'Connect & share',
                    icon: Icons.people,
                    color: const Color(0xFF9C27B0), // Purple 500
                    onTap: () => Navigator.pushNamed(context, AppRoutes.community),
                  ),
                  _ActionCard(
                    title: 'Crop\nHealth',
                    subtitle: 'Encyclopedia',
                    icon: Icons.menu_book,
                    color: const Color(0xFF009688), // Teal 500
                    onTap: () => Navigator.pushNamed(context, AppRoutes.encyclopedia),
                  ),
                  _ActionCard(
                    title: 'My\nFarm',
                    subtitle: 'Manage crops',
                    icon: Icons.agriculture,
                    color: const Color(0xFF795548), // Brown 500
                    onTap: () => Navigator.pushNamed(context, AppRoutes.farm),
                  ),
                  _ActionCard(
                    title: 'View\nHistory',
                    subtitle: 'Past diagnoses',
                    icon: Icons.history,
                    color: const Color(0xFF607D8B), // Blue Grey 500
                    onTap: () => Navigator.pushNamed(context, AppRoutes.history),
                  ),
                  _ActionCard(
                    title: 'Disease\nMap',
                    subtitle: 'Outbreak alerts',
                    icon: Icons.map,
                    color: const Color(0xFFE53935), // Red 600
                    onTap: () => Navigator.pushNamed(context, AppRoutes.diseaseMap),
                  ),
                  _ActionCard(
                    title: 'My\nQuestions',
                    subtitle: 'Expert answers',
                    icon: Icons.question_answer,
                    color: const Color(0xFF3F51B5), // Indigo 500
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myQuestions),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tips section
              Text(
                'Crop Care Tips',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _TipCard(
                title: 'Early Detection Saves Crops',
                description: 'Regularly inspect your crops and use the app to check for any signs of disease.',
                icon: Icons.visibility,
              ),
              const SizedBox(height: 12),
              _TipCard(
                title: 'Good Photo = Accurate Diagnosis',
                description: 'Take clear, close-up photos in good lighting for the best results.',
                icon: Icons.photo_camera,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.smart_toy, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start, // don't push items apart
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            // text section wrapped in Flexible so it can shrink if needed
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
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
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
