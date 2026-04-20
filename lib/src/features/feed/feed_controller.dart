import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/models/post_models.dart';
import '../../services/api_client.dart';

class FeedController extends ChangeNotifier {
  FeedController({required ApiClient apiClient, required bool savedOnly})
    : _apiClient = apiClient,
      _savedOnly = savedOnly;

  final ApiClient _apiClient;
  final bool _savedOnly;

  bool _loading = false;
  bool _loadingMore = false;
  String? _errorMessage;
  List<PostItem> _posts = const [];
  int _page = 0;
  bool _hasNext = false;
  int? _authorFilter;
  int? _followLoadingAuthorId;
  final Set<int> _registeredViewPostIds = <int>{};

  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get errorMessage => _errorMessage;
  List<PostItem> get posts => _posts;
  bool get savedOnly => _savedOnly;
  int get page => _page;
  bool get hasNext => _hasNext;
  int? get authorFilter => _authorFilter;
  int? get followLoadingAuthorId => _followLoadingAuthorId;

  Future<void> load({int page = 0, bool append = false, int? authorId}) async {
    if (append) {
      _loadingMore = true;
    } else {
      _loading = true;
      _errorMessage = null;
      _authorFilter = authorId;
    }
    notifyListeners();

    try {
      final response = await _apiClient.getFeed(
        savedOnly: _savedOnly,
        page: page,
        authorId: authorId ?? _authorFilter,
      );
      _posts = append ? [..._posts, ...response.items] : response.items;
      _page = response.page;
      _hasNext = response.hasNext;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el feed.';
    }

    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> refresh() => load(authorId: _authorFilter);

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasNext) {
      return;
    }
    await load(page: _page + 1, append: true, authorId: _authorFilter);
  }

  Future<void> setAuthorFilter(int? authorId) async {
    await load(authorId: authorId);
  }

  Future<void> toggleSave(PostItem post) async {
    final isSaved = await _apiClient.toggleSave(post.id);
    _posts = _posts
        .map(
          (item) => item.id == post.id
              ? item.copyWith(
                  metrics: item.metrics.copyWith(
                    savedByCurrentUser: isSaved,
                    savesCount: isSaved
                        ? item.metrics.savesCount + 1
                        : math.max(0, item.metrics.savesCount - 1),
                  ),
                )
              : item,
        )
        .where((item) => !_savedOnly || item.metrics.savedByCurrentUser)
        .toList();
    notifyListeners();
  }

  Future<void> toggleReaction(PostItem post, ReactionType reaction) async {
    final metrics = await _apiClient.toggleReaction(post.id, reaction);
    _posts = _posts
        .map(
          (item) => item.id == post.id ? item.copyWith(metrics: metrics) : item,
        )
        .toList();
    notifyListeners();
  }

  Future<void> toggleRepost(PostItem post) async {
    final isActive = await _apiClient.toggleRepost(post.id);
    _posts = _posts
        .map(
          (item) => item.id == post.id
              ? item.copyWith(
                  metrics: item.metrics.copyWith(
                    repostedByCurrentUser: isActive,
                    repostsCount: isActive
                        ? item.metrics.repostsCount + 1
                        : math.max(0, item.metrics.repostsCount - 1),
                  ),
                )
              : item,
        )
        .toList();
    notifyListeners();
  }

  Future<void> registerShare(PostItem post) async {
    final metrics = await _apiClient.registerShare(
      postId: post.id,
      channel: 'MOBILE',
    );
    _posts = _posts
        .map(
          (item) => item.id == post.id ? item.copyWith(metrics: metrics) : item,
        )
        .toList();
    notifyListeners();
  }

  Future<void> updatePickStatus(PostItem post, ResultStatus status) async {
    final updated = await _apiClient.updatePickStatus(
      postId: post.id,
      status: status,
    );
    _posts = _posts.map((item) => item.id == post.id ? updated : item).toList();
    notifyListeners();
  }

  Future<bool?> toggleFollow(PostAuthor author) async {
    _followLoadingAuthorId = author.id;
    notifyListeners();

    try {
      final isFollowing = author.followedByCurrentUser
          ? await _apiClient.unfollowUser(author.id)
          : await _apiClient.followUser(author.id);

      _posts = _posts
          .map(
            (item) => item.author.id == author.id
                ? item.copyWith(
                    author: item.author.copyWith(
                      followedByCurrentUser: isFollowing,
                    ),
                  )
                : item,
          )
          .toList();
      return isFollowing;
    } finally {
      _followLoadingAuthorId = null;
      notifyListeners();
    }
  }

  Future<void> registerView(PostItem post) async {
    if (_registeredViewPostIds.contains(post.id)) {
      return;
    }

    _registeredViewPostIds.add(post.id);
    try {
      await _apiClient.registerView(post.id);
      _posts = _posts
          .map(
            (item) => item.id == post.id
                ? item.copyWith(
                    metrics: item.metrics.copyWith(
                      viewsCount: item.metrics.viewsCount + 1,
                    ),
                  )
                : item,
          )
          .toList();
      notifyListeners();
    } catch (_) {
      // ignore view registration errors in feed
    }
  }

  void updateCommentsCount({
    required int postId,
    required int commentsCount,
  }) {
    _posts = _posts
        .map(
          (item) => item.id == postId
              ? item.copyWith(
                  metrics: item.metrics.copyWith(commentsCount: commentsCount),
                )
              : item,
        )
        .toList();
    notifyListeners();
  }
}
