import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';

/// Expert Community Screen - Expert can create tips/articles
class ExpertCommunityScreen extends ConsumerStatefulWidget {
  const ExpertCommunityScreen({super.key});

  @override
  ConsumerState<ExpertCommunityScreen> createState() => _ExpertCommunityScreenState();
}

class _ExpertCommunityScreenState extends ConsumerState<ExpertCommunityScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _myPostsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/community/posts', queryParameters: {
        'my_posts_only': _myPostsOnly,
      });
      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(response.data['posts'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Expert Tip'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Best practices for rice cultivation',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Share your expert knowledge...',
                ),
                maxLines: 6,
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
              if (titleController.text.length >= 5 && contentController.text.length >= 20) {
                try {
                  final api = ref.read(apiClientProvider);
                  await api.post('/community/posts', data: {
                    'title': titleController.text,
                    'content': contentController.text,
                    'category': 'tip',
                  });
                  Navigator.pop(context);
                  _loadPosts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post created successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title min 5 chars, content min 20 chars')),
                );
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Community'),
        actions: [
          IconButton(
            icon: Icon(_myPostsOnly ? Icons.person : Icons.people),
            onPressed: () {
              setState(() => _myPostsOnly = !_myPostsOnly);
              _loadPosts();
            },
            tooltip: _myPostsOnly ? 'Show All' : 'My Posts Only',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(_myPostsOnly ? 'No posts yet' : 'No expert posts', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Post'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    child: Text(
                                      (post['author_name'] ?? 'E')[0].toUpperCase(),
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              post['author_name'] ?? 'User',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            if (post['is_expert_post'] == true)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Expert',
                                                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Farmer',
                                                  style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          post['created_at']?.toString().split('T')[0] ?? '',
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (post['is_mine'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('My Post', style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                post['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post['content'] ?? '',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.favorite_border, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text('${post['likes_count'] ?? 0}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                  const SizedBox(width: 16),
                                  Icon(Icons.comment_outlined, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text('${post['comments_count'] ?? 0}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }
}
