import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data
    final posts = [
      {
        'name': 'Ramesh Kumar', 'time': '2 hrs ago',
        'title': 'Yellowing leaves in Tomato plants',
        'desc': 'My tomato plants are showing yellow leaves at the bottom. I have watered them regularly. Is this a fungus or nutrient deficiency?',
        'likes': '12', 'comments': '4', 'hasImage': false
      },
      {
        'name': 'Suresh Patel', 'time': '5 hrs ago',
        'title': 'Best fertilizer for Potato in winter?',
        'desc': 'I am planning to sow potatoes next week. Can someone suggest the best NPK ratio for this season?',
        'likes': '8', 'comments': '2', 'hasImage': false
      },
      {
        'name': 'Lakshmi Devi', 'time': '1 day ago',
        'title': 'Successfully harvested 50 quintals of Rice!',
        'desc': 'Thanks to the expert advice here, I had a bumper harvest this season. Sharing some pics!',
        'likes': '45', 'comments': '12', 'hasImage': true
      },
      {
        'name': 'Anil Singh', 'time': '2 days ago',
        'title': 'Market price for Cotton dropping',
        'desc': 'Traders are offering very low prices today. Better to hold the stock for a week if possible.',
        'likes': '15', 'comments': '5', 'hasImage': false
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(context, post, theme, index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Post feature coming soon!')),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Post Query', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post, ThemeData theme, int index) {
    // Generate avatar color based on name length to be deterministic
    final avatarColors = [
      AppTheme.primaryGreen,
      AppTheme.accentOrange,
      AppTheme.secondaryGreen,
      Colors.blue,
      Colors.purple,
    ];
    final avatarColor = avatarColors[post['name'].length % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: avatarColor.withOpacity(0.1),
                child: Text(
                  post['name'][0], 
                  style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['name'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    post['time'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content
          Text(
            post['title'],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post['desc'],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          
          // Optional Image Placeholder
          if (post['hasImage'] == true) ...[
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Image Placeholder', style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton(Icons.thumb_up_alt_outlined, '${post['likes']} Likes', theme),
              _actionButton(Icons.comment_outlined, '${post['comments']} Comments', theme),
              _actionButton(Icons.share_outlined, 'Share', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, ThemeData theme) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
