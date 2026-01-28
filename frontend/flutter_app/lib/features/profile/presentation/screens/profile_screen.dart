import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/auth_provider.dart';

/// Profile screen with user info and logout
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, User user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);
    final expertiseController = TextEditingController(text: user.expertiseDomain);
    final qualificationController = TextEditingController(text: user.qualification);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                if (user.isExpert) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: expertiseController,
                    decoration: const InputDecoration(labelText: 'Expertise'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qualificationController,
                    decoration: const InputDecoration(labelText: 'Qualification'),
                  ),
                ]
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await ref.read(authStateProvider.notifier).updateProfile(
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                  expertiseDomain: user.isExpert ? expertiseController.text.trim() : null,
                  qualification: user.isExpert ? qualificationController.text.trim() : null,
                );
                
                if (context.mounted) {
                   Navigator.pop(context);
                   if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppTheme.primaryGreen),
                     );
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
                     );
                   }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfileDialog(context, ref, user),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(user?.fullName.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(user?.fullName ?? 'User', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text(user?.role ?? 'FARMER', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            _InfoTile(icon: Icons.email, title: 'Email', value: user?.email ?? '-'),
            if (user?.phone != null) _InfoTile(icon: Icons.phone, title: 'Phone', value: user!.phone!),
            if (user?.location != null) _InfoTile(icon: Icons.location_on, title: 'Location', value: user!.location!),
            if (user?.isExpert ?? false) ...[
              _InfoTile(icon: Icons.category, title: 'Expertise', value: user?.expertiseDomain ?? '-'),
              _InfoTile(icon: Icons.school, title: 'Qualification', value: user?.qualification ?? '-'),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.grey.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 15)),
          ]),
        ],
      ),
    );
  }
}
