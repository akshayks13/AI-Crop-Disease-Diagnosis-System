import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';

/// Author info model
class AuthorInfo {
  final String id;
  final String fullName;

  AuthorInfo({required this.id, required this.fullName});

  factory AuthorInfo.fromJson(Map<String, dynamic> json) {
    return AuthorInfo(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'Anonymous',
    );
  }
}

/// Comment model
class Comment {
  final String id;
  final String content;
  final AuthorInfo author;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      author: AuthorInfo.fromJson(json['author'] ?? {}),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

/// Community post model
class CommunityPost {
  final String id;
  final String title;
  final String content;
  final String? imagePath;
  final int likesCount;
  final int commentsCount;
  final AuthorInfo author;
  final bool isLiked;
  final DateTime createdAt;
  final List<Comment> comments;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.likesCount,
    required this.commentsCount,
    required this.author,
    required this.isLiked,
    required this.createdAt,
    this.comments = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imagePath: json['image_path'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      author: AuthorInfo.fromJson(json['author'] ?? {}),
      isLiked: json['is_liked'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      comments: (json['comments'] as List?)
          ?.map((c) => Comment.fromJson(c))
          .toList() ?? [],
    );
  }

  CommunityPost copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<Comment>? comments,
  }) {
    return CommunityPost(
      id: id,
      title: title,
      content: content,
      imagePath: imagePath,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      author: author,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      comments: comments ?? this.comments,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

/// Community state
class CommunityState {
  final List<CommunityPost> posts;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPosts;

  CommunityState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPosts = 0,
  });

  CommunityState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPosts,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPosts: totalPosts ?? this.totalPosts,
    );
  }
}

/// Community notifier
class CommunityNotifier extends StateNotifier<CommunityState> {
  final ApiClient _api;

  CommunityNotifier(this._api) : super(CommunityState()) {
    loadPosts();
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1, posts: []);
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _api.get(
        ApiConfig.communityPosts,
        queryParameters: {'page': state.currentPage, 'page_size': 20},
      );
      final data = response.data as Map<String, dynamic>;
      final postsList = (data['posts'] as List)
          .map((p) => CommunityPost.fromJson(p))
          .toList();
      
      state = state.copyWith(
        posts: refresh ? postsList : [...state.posts, ...postsList],
        isLoading: false,
        totalPosts: data['total'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createPost(String title, String content) async {
    try {
      // Validate minimum lengths before sending
      if (title.length < 5) {
        return 'Title must be at least 5 characters';
      }
      if (content.length < 10) {
        return 'Content must be at least 10 characters';
      }
      
      await _api.post(
        ApiConfig.communityPosts,
        data: {'title': title, 'content': content},
      );
      await loadPosts(refresh: true);
      return null; // null means success
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
      }
      return 'Failed to create post. Please try again.';
    } catch (e) {
      return 'Failed to create post: ${e.toString()}';
    }
  }

  /// Create a post with an optional image attachment using multipart form data.
  /// Uses bytes instead of file path to avoid dart:io dependency (web compatible).
  Future<String?> createPostWithImage(String title, String content, List<int>? imageBytes, String? imageName) async {
    try {
      // Validate minimum lengths before sending
      if (title.length < 5) {
        return 'Title must be at least 5 characters';
      }
      if (content.length < 10) {
        return 'Content must be at least 10 characters';
      }

      final formData = FormData.fromMap({
        'title': title,
        'content': content,
        if (imageBytes != null && imageName != null)
          'image': MultipartFile.fromBytes(imageBytes, filename: imageName),
      });

      await _api.post(
        '${ApiConfig.communityPosts}/with-image',
        data: formData,
      );
      await loadPosts(refresh: true);
      return null; // null means success
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
      }
      return 'Failed to create post. Please try again.';
    } catch (e) {
      return 'Failed to create post: ${e.toString()}';
    }
  }

  Future<void> toggleLike(String postId) async {
    // Optimistic update
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = state.posts[index];
      final newPosts = List<CommunityPost>.from(state.posts);
      newPosts[index] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
      state = state.copyWith(posts: newPosts);
    }
    
    try {
      await _api.post('${ApiConfig.communityPosts}/$postId/like');
    } catch (e) {
      // Revert on error
      await loadPosts(refresh: true);
    }
  }

  Future<String?> addComment(String postId, String content) async {
    try {
      if (content.trim().isEmpty) {
        return 'Comment cannot be empty';
      }
      await _api.post(
        '${ApiConfig.communityPosts}/$postId/comments',
        data: {'content': content},
      );
      await loadPosts(refresh: true);
      return null; // null means success
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
      }
      return 'Failed to add comment';
    } catch (e) {
      return 'Failed to add comment: ${e.toString()}';
    }
  }

  Future<void> loadComments(String postId) async {
    try {
      // Backend returns comments via GET /posts/{id} (PostDetailResponse)
      final response = await _api.get('${ApiConfig.communityPosts}/$postId');
      final data = response.data as Map<String, dynamic>;
      
      // Extract comments from the post detail response
      final List<dynamic> commentsData = data['comments'] ?? [];
      final comments = commentsData.map((c) => Comment.fromJson(c)).toList();

      final index = state.posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = state.posts[index];
        final newPosts = List<CommunityPost>.from(state.posts);
        newPosts[index] = post.copyWith(comments: comments);
        state = state.copyWith(posts: newPosts);
      }
    } catch (e) {
      // Silently fail for now, UI will show existing/empty comments
      print('Error loading comments: $e');
    }
  }

  Future<void> refresh() => loadPosts(refresh: true);
}

/// Provider for community posts
final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final api = ref.watch(apiClientProvider);
  return CommunityNotifier(api);
});
