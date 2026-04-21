import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../core/models/post_models.dart';
import '../../../services/api_client.dart';
import 'post_comment_thread.dart';

Future<int?> showPostCommentsSheet({
  required BuildContext context,
  required ApiClient apiClient,
  required int postId,
  required int initialCommentsCount,
  int? highlightCommentId,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.7,
      child: PostCommentsSheet(
        apiClient: apiClient,
        postId: postId,
        initialCommentsCount: initialCommentsCount,
        highlightCommentId: highlightCommentId,
      ),
    ),
  );
}

class PostCommentsSheet extends StatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.apiClient,
    required this.postId,
    required this.initialCommentsCount,
    this.highlightCommentId,
  });

  final ApiClient apiClient;
  final int postId;
  final int initialCommentsCount;
  final int? highlightCommentId;

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  static const _maxReplyDepth = 2;

  final TextEditingController _commentController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  final Map<int, GlobalKey> _commentKeys = {};
  final ScrollController _scrollController = ScrollController();

  List<CommentItem> _comments = const [];
  bool _loading = true;
  bool _sendingComment = false;
  int? _replyingToCommentId;
  int? _sendingReplyForCommentId;
  final Set<int> _expandedReplyCommentIds = <int>{};
  String? _errorMessage;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _commentsCount = widget.initialCommentsCount;
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
      final comments = await widget.apiClient.getComments(widget.postId);
      if (!mounted) {
        return;
      }

      setState(() {
        _comments = comments;
        _expandedReplyCommentIds.clear();
      });
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
        _errorMessage = 'No se pudieron cargar los comentarios.';
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
      final targetContext = key?.currentContext;
      if (targetContext == null) {
        return;
      }

      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    });
  }

  void _closeSheet() {
    Navigator.of(context).pop(_commentsCount);
  }

  void _scrollToComment(int commentId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final key = _commentKeys[commentId];
      final targetContext = key?.currentContext;
      if (targetContext == null) {
        return;
      }

      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
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
        _commentsCount += 1;
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
        _commentsCount += 1;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colors.borderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comentarios', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '$_commentsCount ${_commentsCount == 1 ? 'comentario' : 'comentarios'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _closeSheet,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
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
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    children: [
                      if (_comments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: colors.softSurface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colors.borderSoft,
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
                                    _expandedReplyCommentIds.remove(commentId);
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
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.borderSoft),
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
                        onPressed: _sendingComment ? null : _submitComment,
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
            ),
          ),
        ],
      ),
    );
  }
}
