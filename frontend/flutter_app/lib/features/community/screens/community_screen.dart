import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/community_provider.dart';
import '../../../../core/api/api_config.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farming Community'),
        // Aligning with Farm Screen specific green
        backgroundColor: Colors.green.shade700, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(communityProvider.notifier).refresh(),
          ),
        ],
      ),
      body: communityState.isLoading && communityState.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : communityState.error != null && communityState.posts.isEmpty
              ? _buildErrorWidget(communityState.error!, colorScheme)
              : communityState.posts.isEmpty
                  ? _buildEmptyWidget(colorScheme)
                  : RefreshIndicator(
                      onRefresh: () => ref.read(communityProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: communityState.posts.length,
                        itemBuilder: (context, index) {
                          final post = communityState.posts[index];
                          return _buildPostCard(post, colorScheme);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(colorScheme),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                post.author.fullName.isNotEmpty 
                    ? post.author.fullName[0].toUpperCase() 
                    : 'U',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              post.author.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(post.timeAgo),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),

          // Post Title & Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Post Image (if any)
          if (post.imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              child: Image.network(
                '${ApiConfig.baseUrl}${post.imagePath}',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Like Button
                TextButton.icon(
                  onPressed: () {
                    ref.read(communityProvider.notifier).toggleLike(post.id);
                  },
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : Colors.grey.shade600,
                    size: 20,
                  ),
                  label: Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      color: post.isLiked ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ),

                // Comment Button
                TextButton.icon(
                  onPressed: () => _showCommentsDialog(post, colorScheme),
                  icon: Icon(Icons.comment_outlined, size: 20, color: Colors.grey.shade600),
                  label: Text(
                    '${post.commentsCount}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),

                const Spacer(),

                // Share Button
                IconButton(
                  icon: Icon(Icons.share_outlined, color: Colors.grey.shade600),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(ColorScheme colorScheme) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Post'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter a catchy title (min 5 chars)...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      if (value.length < 5) {
                        return 'Title must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Share your thoughts (min 10 chars)...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Content is required';
                      }
                      if (value.length < 10) {
                        return 'Content must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Image picker
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setDialogState(() => selectedImage = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedImage != null ? Icons.check_circle : Icons.add_photo_alternate_outlined,
                            color: selectedImage != null ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedImage != null
                                ? 'Image selected'
                                : 'Add image (optional)',
                            style: TextStyle(
                              color: selectedImage != null ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                          if (selectedImage != null) ...[
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setDialogState(() => selectedImage = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
                  String? error;
                  if (selectedImage != null) {
                    // Read bytes from XFile (web compatible, no dart:io)
                    final bytes = await selectedImage!.readAsBytes();
                    final name = selectedImage!.name;
                    error = await ref.read(communityProvider.notifier).createPostWithImage(
                      titleController.text,
                      contentController.text,
                      bytes,
                      name,
                    );
                  } else {
                    error = await ref.read(communityProvider.notifier).createPost(
                      titleController.text,
                      contentController.text,
                    );
                  }
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Post created successfully!'),
                        backgroundColor: error == null ? Colors.green.shade700 : colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsDialog(CommunityPost post, ColorScheme colorScheme) {
    // Load comments when dialog opens
    ref.read(communityProvider.notifier).loadComments(post.id);
    
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            // Get the latest post state
            final posts = ref.watch(communityProvider).posts;
            final currentPost = posts.firstWhere(
              (p) => p.id == post.id,
              orElse: () => post,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comments (${currentPost.commentsCount})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Comment list
                  if (currentPost.comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          // Simple check: if count > 0 but comments empty, likely loading
                          currentPost.commentsCount > 0 
                              ? 'Loading comments...' 
                              : 'No comments yet',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...currentPost.comments.map((comment) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        radius: 16,
                        child: Text(
                          comment.author.fullName.isNotEmpty 
                              ? comment.author.fullName[0].toUpperCase() 
                              : 'U',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      title: Text(comment.author.fullName),
                      subtitle: Text(comment.content),
                    )),

                  const SizedBox(height: 16),

                  // Add comment
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          if (commentController.text.isNotEmpty) {
                            final error = await ref.read(communityProvider.notifier).addComment(
                              post.id,
                              commentController.text,
                            );
                            if (context.mounted) {
                               // Close keyboard
                              FocusScope.of(context).unfocus();
                              commentController.clear();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error ?? 'Comment added!'),
                                  backgroundColor: error == null ? Colors.green.shade700 : colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.send, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildErrorWidget(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load posts',
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(communityProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(ColorScheme colorScheme) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 50,
              color: Colors.green.shade700,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Farmers can ask doubts, share solutions,\nand help each other grow.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          ElevatedButton.icon(
            onPressed: () => _showCreatePostDialog(colorScheme),
            icon: const Icon(Icons.add),
            label: const Text("Create First Post"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
