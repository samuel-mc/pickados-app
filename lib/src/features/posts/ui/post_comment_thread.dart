import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/post_models.dart';

class PostCommentCard extends StatelessWidget {
  const PostCommentCard({
    super.key,
    required this.comment,
    required this.commentKeyFor,
    required this.highlightCommentId,
    required this.expandedReplyCommentIds,
    required this.replyingToCommentId,
    required this.replyControllerFor,
    required this.sendingReplyForCommentId,
    required this.onToggleLike,
    required this.onToggleReplies,
    required this.onToggleReply,
    required this.onSubmitReply,
    required this.maxReplyDepth,
    this.depth = 0,
  });

  final CommentItem comment;
  final GlobalKey Function(int commentId) commentKeyFor;
  final int? highlightCommentId;
  final Set<int> expandedReplyCommentIds;
  final int? replyingToCommentId;
  final TextEditingController Function(int commentId) replyControllerFor;
  final int? sendingReplyForCommentId;
  final Future<void> Function(int commentId) onToggleLike;
  final ValueChanged<int> onToggleReplies;
  final ValueChanged<int> onToggleReply;
  final ValueChanged<int> onSubmitReply;
  final int maxReplyDepth;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(comment.createdAt)?.toLocal();
    final formatted = date == null
        ? comment.createdAt
        : DateFormat('dd MMM • HH:mm').format(date);
    final isReplyBoxOpen = replyingToCommentId == comment.id;
    final replyController = replyControllerFor(comment.id);
    final sendingReply = sendingReplyForCommentId == comment.id;
    final repliesExpanded = depth == 0
        ? expandedReplyCommentIds.contains(comment.id)
        : true;
    final isNestedReply = depth > 0;
    final showReplyingTo =
        depth >= 2 &&
        comment.replyingToUsername != null &&
        comment.replyingToUsername!.trim().isNotEmpty;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
      decoration: BoxDecoration(
        color: highlightCommentId == comment.id
            ? const Color(0xFFFFF2E8)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isNestedReply && highlightCommentId != comment.id
            ? null
            : Border.all(
                color: highlightCommentId == comment.id
                    ? const Color(0xFFED5F2F)
                    : const Color(0xFFE3EBF3),
              ),
        boxShadow: highlightCommentId == comment.id
            ? const [
                BoxShadow(
                  color: Color(0x1AED5F2F),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNestedReply)
            Container(
              width: 2,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFED5F2F),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.author.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${comment.author.username} • $formatted',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        onToggleLike(comment.id);
                      },
                      icon: Icon(
                        comment.likedByCurrentUser
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 16,
                      ),
                      label: Text('${comment.likesCount}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: comment.likedByCurrentUser
                            ? const Color(0xFF0F4C81)
                            : const Color(0xFFEAF3FB),
                        foregroundColor: comment.likedByCurrentUser
                            ? Colors.white
                            : const Color(0xFF0F4C81),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                if (showReplyingTo) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Respondiendo a @${comment.replyingToUsername}',
                    style: const TextStyle(
                      color: Color(0xFF0F4C81),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (depth < maxReplyDepth)
                      TextButton.icon(
                        onPressed: () {
                          onToggleReply(comment.id);
                        },
                        icon: Icon(
                          isReplyBoxOpen
                              ? Icons.close_rounded
                              : Icons.reply_rounded,
                          size: 18,
                        ),
                        label: Text(isReplyBoxOpen ? 'Cancelar' : 'Responder'),
                      ),
                    if (depth == 0 && comment.replies.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          onToggleReplies(comment.id);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          repliesExpanded
                              ? 'Ocultar respuestas -'
                              : 'Ver ${comment.replies.length} ${comment.replies.length == 1 ? 'respuesta' : 'respuestas'} +',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (depth < maxReplyDepth && isReplyBoxOpen) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE3EBF3)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: replyController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Escribe una respuesta',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: sendingReply
                                ? null
                                : () {
                                    onSubmitReply(comment.id);
                                  },
                            child: sendingReply
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Responder'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (comment.replies.isNotEmpty && repliesExpanded) ...[
                  const SizedBox(height: 12),
                  Column(
                    children: comment.replies
                        .map(
                          (reply) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: PostCommentCard(
                              key: commentKeyFor(reply.id),
                              comment: reply,
                              commentKeyFor: commentKeyFor,
                              highlightCommentId: highlightCommentId,
                              expandedReplyCommentIds: expandedReplyCommentIds,
                              replyingToCommentId: replyingToCommentId,
                              replyControllerFor: replyControllerFor,
                              sendingReplyForCommentId:
                                  sendingReplyForCommentId,
                              onToggleLike: onToggleLike,
                              onToggleReplies: onToggleReplies,
                              onToggleReply: onToggleReply,
                              onSubmitReply: onSubmitReply,
                              maxReplyDepth: maxReplyDepth,
                              depth: depth + 1,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<CommentItem> updateCommentTree(
  List<CommentItem> comments,
  int commentId,
  CommentItem Function(CommentItem current) updater,
) {
  return comments.map((comment) {
    if (comment.id == commentId) {
      return updater(comment);
    }

    if (comment.replies.isEmpty) {
      return comment;
    }

    return comment.copyWith(
      replies: updateCommentTree(comment.replies, commentId, updater),
    );
  }).toList();
}

List<CommentItem> insertReplyIntoTree(
  List<CommentItem> comments,
  int parentCommentId,
  CommentItem reply,
) {
  return comments.map((comment) {
    if (comment.id == parentCommentId) {
      return comment.copyWith(replies: [...comment.replies, reply]);
    }

    if (comment.replies.isEmpty) {
      return comment;
    }

    return comment.copyWith(
      replies: insertReplyIntoTree(comment.replies, parentCommentId, reply),
    );
  }).toList();
}
