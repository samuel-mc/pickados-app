import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/post_models.dart';
import '../../../core/models/profile_models.dart';
import '../../../services/api_client.dart';
import '../../posts/ui/post_detail_screen.dart';
import '../../posts/share_post.dart';
import '../../feed/ui/post_card.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.apiClient,
    required this.userId,
    required this.currentUserId,
  });

  final ApiClient apiClient;
  final int userId;
  final int? currentUserId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _loading = true;
  bool _followLoading = false;
  String? _errorMessage;
  PublicProfile? _profile;
  List<PostItem> _posts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getPublicProfile(widget.userId),
        widget.apiClient.getPostsByUser(widget.userId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = results[0] as PublicProfile;
        _posts = (results[1] as PagedResponse<PostItem>).items;
      });
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
        _errorMessage = 'No se pudo cargar el perfil publico.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || profile.selfProfile) {
      return;
    }

    setState(() {
      _followLoading = true;
    });

    try {
      final nextActive = profile.followedByCurrentUser
          ? await widget.apiClient.unfollowUser(profile.id)
          : await widget.apiClient.followUser(profile.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile.copyWith(
          followedByCurrentUser: nextActive,
          followersCount: nextActive
              ? profile.followersCount + 1
              : (profile.followersCount > 0 ? profile.followersCount - 1 : 0),
        );
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el seguimiento.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _followLoading = false;
        });
      }
    }
  }

  void _replacePost(PostItem updated) {
    setState(() {
      _posts = _posts.map((item) => item.id == updated.id ? updated : item).toList();
    });
  }

  Future<void> _toggleSave(PostItem post) async {
    final isSaved = await widget.apiClient.toggleSave(post.id);
    _replacePost(
      post.copyWith(
        metrics: post.metrics.copyWith(
          savedByCurrentUser: isSaved,
          savesCount: isSaved
              ? post.metrics.savesCount + 1
              : (post.metrics.savesCount > 0 ? post.metrics.savesCount - 1 : 0),
        ),
      ),
    );
  }

  Future<void> _toggleReaction(PostItem post, ReactionType reaction) async {
    final metrics = await widget.apiClient.toggleReaction(post.id, reaction);
    _replacePost(post.copyWith(metrics: metrics));
  }

  Future<void> _toggleRepost(PostItem post) async {
    final isActive = await widget.apiClient.toggleRepost(post.id);
    _replacePost(
      post.copyWith(
        metrics: post.metrics.copyWith(
          repostedByCurrentUser: isActive,
          repostsCount: isActive
              ? post.metrics.repostsCount + 1
              : (post.metrics.repostsCount > 0 ? post.metrics.repostsCount - 1 : 0),
        ),
      ),
    );
  }

  Future<void> _share(PostItem post) async {
    final shared = await sharePostLink(context: context, postId: post.id);
    if (!shared) {
      return;
    }

    final metrics = await widget.apiClient.registerShare(
      postId: post.id,
      channel: 'MOBILE',
    );
    _replacePost(post.copyWith(metrics: metrics));
  }

  Future<void> _updatePickStatus(PostItem post, ResultStatus status) async {
    final updated = await widget.apiClient.updatePickStatus(
      postId: post.id,
      status: status,
    );
    _replacePost(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.pageGradientBottom,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return Scaffold(
        backgroundColor: colors.pageGradientBottom,
        appBar: AppBar(title: const Text('Perfil publico')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage ?? 'No se pudo cargar el perfil.',
                  textAlign: TextAlign.center,
                ),
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
        ),
      );
    }

    final profile = _profile!;
    final initials = profile.fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: colors.pageGradientBottom,
      appBar: AppBar(
        title: const Text('Perfil publico'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageGradientTop, colors.pageGradientBottom],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 78,
                            width: 78,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: profile.avatarUrl == null
                                  ? LinearGradient(
                                      colors: [theme.colorScheme.primary, colors.danger],
                                    )
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: profile.avatarUrl != null
                                ? Image.network(
                                    profile.avatarUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Text(
                                    initials.isEmpty ? 'P' : initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.fullName,
                                        style: theme.textTheme.headlineMedium,
                                      ),
                                    ),
                                    if (profile.validatedTipster)
                                      Icon(
                                        Icons.verified_rounded,
                                        color: colors.success,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${profile.username}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _StatChip(
                                      label: 'Seguidores',
                                      value: '${profile.followersCount}',
                                    ),
                                    _StatChip(
                                      label: 'Siguiendo',
                                      value: '${profile.followingCount}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        profile.bio?.trim().isNotEmpty == true
                            ? profile.bio!
                            : 'Este tipster aun no ha agregado biografia.',
                      ),
                      const SizedBox(height: 18),
                      if (!profile.selfProfile)
                        ElevatedButton.icon(
                          onPressed: _followLoading
                              ? null
                              : () {
                                  _toggleFollow();
                                },
                          icon: Icon(
                            profile.followedByCurrentUser
                                ? Icons.person_remove_alt_1_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                          label: Text(
                            profile.followedByCurrentUser
                                ? 'Dejar de seguir'
                                : 'Seguir tipster',
                          ),
                        ),
                      if (profile.preferredCompetitions.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Competiciones favoritas',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: profile.preferredCompetitions
                              .map((item) => Chip(label: Text(item.name)))
                              .toList(),
                        ),
                      ],
                      if (profile.preferredTeams.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Equipos favoritos',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: profile.preferredTeams
                              .map((item) => Chip(label: Text(item.name)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Posts del tipster',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_posts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Este tipster aun no tiene publicaciones visibles.'),
                  ),
                )
              else
                ..._posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PickaPostCard(
                      post: post,
                      onSave: () => _toggleSave(post),
                      onReaction: (reaction) => _toggleReaction(post, reaction),
                      onRepost: () => _toggleRepost(post),
                      onShare: () => _share(post),
                      currentUserId: widget.currentUserId,
                      onUpdatePickStatus: (status) => _updatePickStatus(post, status),
                      onViewProfile: null,
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
                          _load();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
