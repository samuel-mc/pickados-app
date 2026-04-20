import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../services/api_client.dart';
import '../../profile/ui/public_profile_screen.dart';
import '../feed_controller.dart';
import 'post_card.dart';
import '../../posts/ui/post_comments_sheet.dart';
import '../../posts/ui/post_detail_screen.dart';
import '../../posts/share_post.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.apiClient,
    required this.controller,
    required this.currentUserId,
    required this.baseTitle,
    required this.baseSubtitle,
  });

  final ApiClient apiClient;
  final FeedController controller;
  final int? currentUserId;
  final String baseTitle;
  final String baseSubtitle;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load(authorId: widget.controller.authorFilter);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PickadosColors>()!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: widget.controller.refresh,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.pageGradientTop, colors.pageGradientBottom],
              ),
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (widget.controller.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (widget.controller.errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _FeedStateCard(
                      title: 'No pudimos cargar esta vista',
                      message: widget.controller.errorMessage!,
                      actionLabel: 'Reintentar',
                      onAction: widget.controller.load,
                    ),
                  )
                else if (widget.controller.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _FeedStateCard(
                      title: widget.controller.savedOnly
                          ? 'Aun no tienes posts guardados'
                          : 'Tu feed aun esta vacio',
                      message: widget.controller.savedOnly
                          ? 'Cuando guardes picks desde la comunidad, apareceran aqui.'
                          : 'La conexion ya esta lista; el siguiente paso es extender composer, comentarios y detalle.',
                      actionLabel: 'Actualizar',
                      onAction: widget.controller.load,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = widget.controller.posts[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == widget.controller.posts.length - 1
                                ? 0
                                : 16,
                          ),
                          child: PickaPostCard(
                            post: post,
                            key: ValueKey(post.id),
                            onSave: () => widget.controller.toggleSave(post),
                            onReaction: (reaction) =>
                                widget.controller.toggleReaction(post, reaction),
                            onRepost: () async {
                              await widget.controller.toggleRepost(post);
                            },
                            onShare: () async {
                              final shared = await sharePostLink(
                                context: context,
                                postId: post.id,
                              );
                              if (shared) {
                                await widget.controller.registerShare(post);
                              }
                            },
                            currentUserId: widget.currentUserId,
                            onUpdatePickStatus: (status) async {
                              await widget.controller.updatePickStatus(
                                post,
                                status,
                              );
                            },
                            onRegisterView: () =>
                                widget.controller.registerView(post),
                            onToggleFollow: post.author.id == widget.currentUserId
                                ? null
                                : () async {
                                    await widget.controller.toggleFollow(
                                      post.author,
                                    );
                                  },
                            followLoading:
                                widget.controller.followLoadingAuthorId ==
                                post.author.id,
                            onFilterByAuthor: widget.controller.savedOnly
                                ? null
                                : () => widget.controller.setAuthorFilter(
                                    post.author.id,
                                  ),
                            onViewProfile: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => PublicProfileScreen(
                                    apiClient: widget.apiClient,
                                    userId: post.author.id,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                widget.controller.refresh();
                              }
                            },
                            onOpenImage: post.mediaUrls.isEmpty
                                ? null
                                : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) => PostDetailScreen(
                                          apiClient: widget.apiClient,
                                          postId: post.id,
                                          currentUserId: widget.currentUserId,
                                        ),
                                      ),
                                    );
                                    if (context.mounted) {
                                      widget.controller.refresh();
                                    }
                                  },
                            onOpenDetail: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => PostDetailScreen(
                                    apiClient: widget.apiClient,
                                    postId: post.id,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                widget.controller.refresh();
                              }
                            },
                            onOpenComments: () async {
                              final commentsCount = await showPostCommentsSheet(
                                context: context,
                                apiClient: widget.apiClient,
                                postId: post.id,
                                initialCommentsCount: post.metrics.commentsCount,
                              );
                              if (commentsCount != null && context.mounted) {
                                widget.controller.updateCommentsCount(
                                  postId: post.id,
                                  commentsCount: commentsCount,
                                );
                              }
                            },
                          ),
                        );
                      }, childCount: widget.controller.posts.length),
                    ),
                  ),
                if (!widget.controller.loading &&
                    widget.controller.posts.isNotEmpty &&
                    widget.controller.hasNext)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: widget.controller.loadingMore
                              ? null
                              : widget.controller.loadMore,
                          child: Text(
                            widget.controller.loadingMore
                                ? 'Cargando...'
                                : 'Cargar mas',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _FeedStateCard extends StatelessWidget {
  const _FeedStateCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sports_basketball_rounded,
                    size: 42,
                    color: Color(0xFF0F4C81),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      onAction();
                    },
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
