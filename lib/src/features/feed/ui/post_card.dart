import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/post_models.dart';

class PickaPostCard extends StatefulWidget {
  const PickaPostCard({
    super.key,
    required this.post,
    required this.onSave,
    required this.onReaction,
    required this.onRepost,
    required this.onShare,
    required this.currentUserId,
    required this.onUpdatePickStatus,
    this.onViewProfile,
    this.onOpenImage,
    this.onOpenDetail,
    this.onOpenComments,
    this.onToggleFollow,
    this.followLoading = false,
    this.onFilterByAuthor,
    this.onRegisterView,
  });

  final PostItem post;
  final Future<void> Function() onSave;
  final Future<void> Function(ReactionType reaction) onReaction;
  final Future<void> Function() onRepost;
  final Future<void> Function() onShare;
  final int? currentUserId;
  final Future<void> Function(ResultStatus status) onUpdatePickStatus;
  final Future<void> Function()? onViewProfile;
  final Future<void> Function()? onOpenImage;
  final VoidCallback? onOpenDetail;
  final Future<void> Function()? onOpenComments;
  final Future<void> Function()? onToggleFollow;
  final bool followLoading;
  final Future<void> Function()? onFilterByAuthor;
  final Future<void> Function()? onRegisterView;

  @override
  State<PickaPostCard> createState() => _PickaPostCardState();
}

class _PickaPostCardState extends State<PickaPostCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterView?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    final post = widget.post;
    final imageUrl = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null;
    final isOwner = widget.currentUserId == post.author.id;
    final canFollow = widget.onToggleFollow != null && !isOwner;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: widget.onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.onViewProfile,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(
                      imageUrl: post.author.avatarUrl,
                      seed: post.author.name,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  post.author.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (post.author.validatedTipster)
                                Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: colors.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${post.author.username} • ${_formatDate(post.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onViewProfile != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                      ),
                  ],
                ),
              ),
              if (canFollow) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canFollow)
                      FilledButton.tonalIcon(
                        onPressed: widget.followLoading
                            ? null
                            : widget.onToggleFollow,
                        icon: Icon(
                          post.author.followedByCurrentUser
                              ? Icons.person_remove_alt_1_rounded
                              : Icons.person_add_alt_1_rounded,
                        ),
                        label: Text(
                          widget.followLoading
                              ? 'Actualizando...'
                              : post.author.followedByCurrentUser
                              ? 'Siguiendo'
                              : 'Seguir',
                        ),
                      ),
                  ],
                ),
              ],
              if (post.content.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(post.content, style: theme.textTheme.bodyLarge),
              ],
              if (imageUrl != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.onOpenImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 520),
                      color: colors.softSurface,
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colors.softSurface,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: colors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: post.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.blueSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (post.simplePick != null) ...[
                const SizedBox(height: 16),
                _PickMeta(
                  pick: post.simplePick!,
                  currentStatus: post.currentResultStatus,
                  isOwner: isOwner,
                  onUpdatePickStatus: widget.onUpdatePickStatus,
                ),
              ],
              if (post.parleySelections.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ParleyMeta(
                  selections: post.parleySelections,
                  parley: post.parley,
                  currentStatus: post.currentResultStatus,
                  isOwner: isOwner,
                  onUpdatePickStatus: widget.onUpdatePickStatus,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionMetricPill(
                    icon: Icons.thumb_up_alt_outlined,
                    value: post.metrics.likesCount,
                    onPressed: () => widget.onReaction(ReactionType.like),
                    active: post.metrics.currentUserReaction == 'LIKE',
                  ),
                  _ActionMetricPill(
                    icon: Icons.thumb_down_alt_outlined,
                    value: post.metrics.dislikesCount,
                    onPressed: () => widget.onReaction(ReactionType.dislike),
                    active: post.metrics.currentUserReaction == 'DISLIKE',
                    activeColor: colors.danger,
                  ),
                  _ActionMetricPill(
                    icon: Icons.mode_comment_outlined,
                    value: post.metrics.commentsCount,
                    onPressed: widget.onOpenComments,
                  ),
                  _ActionMetricPill(
                    icon: Icons.repeat_rounded,
                    value: post.metrics.repostsCount,
                    onPressed: widget.onRepost,
                    active: post.metrics.repostedByCurrentUser,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton.filledTonal(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share_rounded),
                  ),
                  IconButton.filled(
                    onPressed: widget.onSave,
                    style: IconButton.styleFrom(
                      backgroundColor: post.metrics.savedByCurrentUser
                          ? colors.danger
                          : theme.colorScheme.primary,
                    ),
                    icon: Icon(
                      post.metrics.savedByCurrentUser
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }
    return DateFormat('dd MMM • HH:mm').format(parsed);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.seed});

  final String? imageUrl;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PickadosColors>()!;
    final initials = seed
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: imageUrl == null
            ? LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, colors.danger],
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  initials.isEmpty ? 'P' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            )
          : Text(
              initials.isEmpty ? 'P' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _PickMeta extends StatelessWidget {
  const _PickMeta({
    required this.pick,
    required this.currentStatus,
    required this.isOwner,
    required this.onUpdatePickStatus,
  });

  final PickSummary pick;
  final String currentStatus;
  final bool isOwner;
  final Future<void> Function(ResultStatus status) onUpdatePickStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PickadosColors>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.blueSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pick.sport} • ${pick.league}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusMenu(
                currentStatus: currentStatus,
                isOwner: isOwner,
                onSelected: onUpdatePickStatus,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniTag(label: 'Stake ${pick.stake.toStringAsFixed(2)}'),
              _MiniTag(label: _resultLabel(currentStatus)),
              if (pick.sportsbookName != null &&
                  pick.sportsbookName!.isNotEmpty)
                _MiniTag(label: pick.sportsbookName!),
              _MiniTag(label: 'Simple pick'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParleyMeta extends StatelessWidget {
  const _ParleyMeta({
    required this.selections,
    required this.parley,
    required this.currentStatus,
    required this.isOwner,
    required this.onUpdatePickStatus,
  });

  final List<ParleySelectionSummary> selections;
  final ParleySummary? parley;
  final String currentStatus;
  final bool isOwner;
  final Future<void> Function(ResultStatus status) onUpdatePickStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PickadosColors>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.warmSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parley de ${selections.length} selecciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusMenu(
                currentStatus: currentStatus,
                isOwner: isOwner,
                onSelected: onUpdatePickStatus,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (parley != null)
                _MiniTag(label: 'Stake ${parley!.stake.toStringAsFixed(2)}'),
              _MiniTag(label: _resultLabel(currentStatus)),
              if (parley?.sportsbookName != null &&
                  parley!.sportsbookName!.isNotEmpty)
                _MiniTag(label: parley!.sportsbookName!),
            ],
          ),
          const SizedBox(height: 10),
          ...selections
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${item.sport} / ${item.league}'),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({
    required this.currentStatus,
    required this.isOwner,
    required this.onSelected,
  });

  final String currentStatus;
  final bool isOwner;
  final Future<void> Function(ResultStatus status) onSelected;

  @override
  Widget build(BuildContext context) {
    final label = _resultLabel(currentStatus);
    final color = _statusColor(currentStatus);

    if (!isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      );
    }

    return PopupMenuButton<ResultStatus>(
      onSelected: (status) {
        onSelected(status);
      },
      itemBuilder: (context) => ResultStatus.values
          .map(
            (status) => PopupMenuItem(value: status, child: Text(status.label)),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'WON':
      return const Color(0xFF1D9A6C);
    case 'LOST':
      return const Color(0xFFFF7A45);
    case 'VOID':
      return const Color(0xFF6A7686);
    default:
      return const Color(0xFF2E7CF6);
  }
}

String _resultLabel(String status) {
  switch (status) {
    case 'WON':
      return 'Ganado';
    case 'LOST':
      return 'Perdido';
    case 'VOID':
      return 'Void';
    default:
      return 'Pendiente';
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionMetricPill extends StatelessWidget {
  const _ActionMetricPill({
    required this.icon,
    required this.value,
    required this.onPressed,
    this.active = false,
    this.activeColor = const Color(0xFF0F4C81),
  });

  final IconData icon;
  final int value;
  final Future<void> Function()? onPressed;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    final foregroundColor = active ? Colors.white : theme.colorScheme.primary;

    return Material(
      color: active ? activeColor : colors.blueSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed == null ? null : () => onPressed!.call(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
