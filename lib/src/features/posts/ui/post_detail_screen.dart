import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/models/post_models.dart';
import '../../../services/api_client.dart';
import '../../feed/ui/post_card.dart';
import '../../profile/ui/public_profile_screen.dart';
import '../share_post.dart';
import 'post_comment_thread.dart';
import 'post_image_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.apiClient,
    required this.postId,
    this.currentUserId,
    this.highlightCommentId,
  });

  final ApiClient apiClient;
  final int postId;
  final int? currentUserId;
  final int? highlightCommentId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static const _maxReplyDepth = 2;
  final TextEditingController _commentController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  final Map<int, GlobalKey> _commentKeys = {};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsSectionKey = GlobalKey();
  bool _loading = true;
  bool _sendingComment = false;
  int? _replyingToCommentId;
  int? _sendingReplyForCommentId;
  final Set<int> _expandedReplyCommentIds = <int>{};
  String? _errorMessage;
  PostItem? _post;
  List<CommentItem> _comments = const [];
  bool _registeredView = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  TextEditingController _replyControllerFor(int commentId) {
    return _replyControllers.putIfAbsent(commentId, TextEditingController.new);
  }

  GlobalKey _commentKeyFor(int commentId) {
    return _commentKeys.putIfAbsent(commentId, GlobalKey.new);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getPostDetail(widget.postId),
        widget.apiClient.getComments(widget.postId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = results[0] as PostItem;
        _comments = results[1] as List<CommentItem>;
        _expandedReplyCommentIds.clear();
      });
      _registerViewIfNeeded();
      _scheduleHighlightScroll();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No se pudo cargar el detalle del post.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _scheduleHighlightScroll() {
    final targetId = widget.highlightCommentId;
    if (targetId == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final key = _commentKeys[targetId];
      final context = key?.currentContext;
      if (context == null) {
        return;
      }

      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    });
  }

  void _registerViewIfNeeded() {
    final post = _post;
    if (_registeredView || post == null || widget.currentUserId == null) {
      return;
    }

    _registeredView = true;
    widget.apiClient
        .registerView(post.id)
        .then((_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _post = _post?.copyWith(
              metrics: _post!.metrics.copyWith(
                viewsCount: _post!.metrics.viewsCount + 1,
              ),
            );
          });
        })
        .catchError((_) {
          // ignore
        });
  }

  void _scrollToComment(int commentId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final key = _commentKeys[commentId];
      final context = key?.currentContext;
      if (context == null) {
        return;
      }

      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    });
  }

  void _scrollToCommentsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final targetContext = _commentsSectionKey.currentContext;
      if (targetContext == null) {
        return;
      }

      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _sendingComment = true;
    });

    try {
      final created = await widget.apiClient.createComment(
        postId: widget.postId,
        content: text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = [..._comments, created];
        _post = _post?.copyWith(
          metrics: _post!.metrics.copyWith(
            commentsCount: _post!.metrics.commentsCount + 1,
          ),
        );
      });
      _commentController.clear();
      _scrollToComment(created.id);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo publicar el comentario.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingComment = false;
        });
      }
    }
  }

  Future<void> _submitReply({required int parentCommentId}) async {
    final controller = _replyControllerFor(parentCommentId);
    final text = controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _sendingReplyForCommentId = parentCommentId;
    });

    try {
      final created = await widget.apiClient.createComment(
        postId: widget.postId,
        content: text,
        parentCommentId: parentCommentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = insertReplyIntoTree(_comments, parentCommentId, created);
        _post = _post?.copyWith(
          metrics: _post!.metrics.copyWith(
            commentsCount: _post!.metrics.commentsCount + 1,
          ),
        );
        _expandedReplyCommentIds.add(parentCommentId);
        _replyingToCommentId = null;
        _sendingReplyForCommentId = null;
      });
      controller.clear();
      _scrollToComment(created.id);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendingReplyForCommentId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendingReplyForCommentId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo publicar la respuesta.')),
      );
    }
  }

  Future<void> _toggleCommentLike(int commentId) async {
    try {
      final updated = await widget.apiClient.toggleCommentLike(
        postId: widget.postId,
        commentId: commentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = updateCommentTree(
          _comments,
          commentId,
          (current) => updated.copyWith(replies: current.replies),
        );
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el like.')),
      );
    }
  }

  Future<void> _toggleSave() async {
    final post = _post;
    if (post == null) {
      return;
    }

    final isSaved = await widget.apiClient.toggleSave(post.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _post = post.copyWith(
        metrics: post.metrics.copyWith(
          savedByCurrentUser: isSaved,
          savesCount: isSaved
              ? post.metrics.savesCount + 1
              : math.max(0, post.metrics.savesCount - 1),
        ),
      );
    });
  }

  Future<void> _toggleReaction(ReactionType reaction) async {
    final post = _post;
    if (post == null) {
      return;
    }

    final metrics = await widget.apiClient.toggleReaction(post.id, reaction);
    if (!mounted) {
      return;
    }

    setState(() {
      _post = post.copyWith(metrics: metrics);
    });
  }

  Future<void> _toggleRepost() async {
    final post = _post;
    if (post == null) {
      return;
    }

    final isActive = await widget.apiClient.toggleRepost(post.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _post = post.copyWith(
        metrics: post.metrics.copyWith(
          repostedByCurrentUser: isActive,
          repostsCount: isActive
              ? post.metrics.repostsCount + 1
              : math.max(0, post.metrics.repostsCount - 1),
        ),
      );
    });
  }

  Future<void> _sharePost() async {
    final post = _post;
    if (post == null) {
      return;
    }

    final shared = await sharePostLink(context: context, postId: post.id);
    if (!shared) {
      return;
    }

    final metrics = await widget.apiClient.registerShare(
      postId: post.id,
      channel: 'MOBILE',
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _post = post.copyWith(metrics: metrics);
    });
  }

  Future<void> _updatePickStatus(ResultStatus status) async {
    final post = _post;
    if (post == null) {
      return;
    }

    final updated = await widget.apiClient.updatePickStatus(
      postId: post.id,
      status: status,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _post = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del post')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _load();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(4),
                children: [
                  PickaPostCard(
                    post: _post!,
                    onSave: _toggleSave,
                    onReaction: _toggleReaction,
                    onRepost: _toggleRepost,
                    onShare: _sharePost,
                    currentUserId: widget.currentUserId,
                    onUpdatePickStatus: _updatePickStatus,
                    onRegisterView: () async {
                      _registerViewIfNeeded();
                    },
                    onViewProfile: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => PublicProfileScreen(
                            apiClient: widget.apiClient,
                            userId: _post!.author.id,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                      if (context.mounted) {
                        _load();
                      }
                    },
                    onOpenImage: _post!.mediaUrls.isEmpty
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => PostImageScreen(
                                  imageUrl: _post!.mediaUrls.first,
                                ),
                              ),
                            );
                          },
                    onOpenComments: () async {
                      _scrollToCommentsSection();
                    },
                  ),
                  const SizedBox(height: 18),
                  Card(
                    key: _commentsSectionKey,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comentarios',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFD),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE3EBF3),
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _commentController,
                                  minLines: 2,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    labelText: 'Escribe tu comentario',
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: _sendingComment
                                        ? null
                                        : () {
                                            _submitComment();
                                          },
                                    child: _sendingComment
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Enviar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_comments.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFD),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFE3EBF3),
                                ),
                              ),
                              child: const Text(
                                'Aun no hay comentarios en este post.',
                                style: TextStyle(color: Color(0xFF5F6E7D)),
                              ),
                            )
                          else
                            ..._comments.map(
                              (comment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PostCommentCard(
                                  key: _commentKeyFor(comment.id),
                                  comment: comment,
                                  commentKeyFor: _commentKeyFor,
                                  maxReplyDepth: _maxReplyDepth,
                                  highlightCommentId: widget.highlightCommentId,
                                  expandedReplyCommentIds:
                                      _expandedReplyCommentIds,
                                  replyingToCommentId: _replyingToCommentId,
                                  replyControllerFor: _replyControllerFor,
                                  sendingReplyForCommentId:
                                      _sendingReplyForCommentId,
                                  onToggleLike: _toggleCommentLike,
                                  onToggleReplies: (commentId) {
                                    setState(() {
                                      if (_expandedReplyCommentIds.contains(
                                        commentId,
                                      )) {
                                        _expandedReplyCommentIds.remove(
                                          commentId,
                                        );
                                      } else {
                                        _expandedReplyCommentIds.add(commentId);
                                      }
                                    });
                                  },
                                  onToggleReply: (commentId) {
                                    setState(() {
                                      _replyingToCommentId =
                                          _replyingToCommentId == commentId
                                          ? null
                                          : commentId;
                                    });
                                  },
                                  onSubmitReply: (parentCommentId) {
                                    _submitReply(
                                      parentCommentId: parentCommentId,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
