import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/catalog_models.dart';
import '../../../core/models/post_models.dart';
import '../../../core/models/profile_models.dart';
import '../../../services/api_client.dart';
import '../../auth/session_controller.dart';
import '../../feed/ui/post_card.dart';
import '../../posts/share_post.dart';
import '../../posts/ui/post_comments_sheet.dart';
import '../../posts/ui/post_detail_screen.dart';
import 'profile_avatar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final SessionController sessionController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _errorMessage;
  MeProfile? _profile;
  PublicProfile? _publicProfile;
  List<PostItem> _posts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currentUserId = widget.sessionController.session?.userId;
    if (currentUserId == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'No se pudo identificar la sesion actual.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getMyProfile(),
        widget.apiClient.getPublicProfile(currentUserId),
        widget.apiClient.getPostsByUser(currentUserId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = results[0] as MeProfile;
        _publicProfile = results[1] as PublicProfile;
        _posts = (results[2] as PagedResponse<PostItem>).items;
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
        _errorMessage = 'No se pudo cargar tu perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> openEditor() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          apiClient: widget.apiClient,
          sessionController: widget.sessionController,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _load();
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final publicProfile = _publicProfile;
    final initials = (profile.fullName.isNotEmpty ? profile.fullName : profile.username)
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return RefreshIndicator(
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
                      _ProfileAvatar(
                        avatarUrl: profile.avatarUrl,
                        initials: initials.isEmpty ? 'P' : initials,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName.isNotEmpty ? profile.fullName : profile.username,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${profile.username}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(profile.email, style: theme.textTheme.bodyMedium),
                            if (publicProfile?.validatedTipster == true) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.success.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: colors.success,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tipster validado',
                                      style: TextStyle(
                                        color: colors.success,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (publicProfile != null) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _StatPill(
                                    label: 'Seguidores',
                                    value: publicProfile.followersCount,
                                  ),
                                  const SizedBox(width: 10),
                                  _StatPill(
                                    label: 'Siguiendo',
                                    value: publicProfile.followingCount,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: openEditor,
                        tooltip: 'Editar perfil',
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile.bio?.trim().isNotEmpty == true
                        ? profile.bio!
                        : 'Agrega una bio para que otros usuarios conozcan mejor tu perfil.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  if (profile.preferredCompetitions.isNotEmpty) ...[
                    Text('Competiciones favoritas', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profile.preferredCompetitions
                          .map((item) => _TagChip(label: item.name))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (profile.preferredTeams.isNotEmpty) ...[
                    Text('Equipos favoritos', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profile.preferredTeams
                          .map((item) => _TagChip(label: item.name))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('Mis posts', style: theme.textTheme.titleLarge),
              ),
              Text(
                '${_posts.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  'Todavia no has publicado posts.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ..._posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PickaPostCard(
                  key: ValueKey(post.id),
                  post: post,
                  currentUserId: widget.sessionController.session?.userId,
                  onSave: () => _toggleSave(post),
                  onReaction: (reaction) => _toggleReaction(post, reaction),
                  onRepost: () => _toggleRepost(post),
                  onShare: () => _share(post),
                  onUpdatePickStatus: (status) => _updatePickStatus(post, status),
                  onOpenImage: post.mediaUrls.isEmpty
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => PostDetailScreen(
                                apiClient: widget.apiClient,
                                postId: post.id,
                                currentUserId:
                                    widget.sessionController.session?.userId,
                              ),
                            ),
                          );
                          if (context.mounted) {
                            _load();
                          }
                        },
                  onOpenDetail: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => PostDetailScreen(
                          apiClient: widget.apiClient,
                          postId: post.id,
                          currentUserId: widget.sessionController.session?.userId,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      _load();
                    }
                  },
                  onOpenComments: () async {
                    final commentsCount = await showPostCommentsSheet(
                      context: context,
                      apiClient: widget.apiClient,
                      postId: post.id,
                      initialCommentsCount: post.metrics.commentsCount,
                    );
                    if (commentsCount != null && mounted) {
                      _replacePost(
                        post.copyWith(
                          metrics: post.metrics.copyWith(commentsCount: commentsCount),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.apiClient,
    required this.sessionController,
  });

  final ApiClient apiClient;
  final SessionController sessionController;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _bioController = TextEditingController();

  MeProfile? _profile;
  List<CompetitionItem> _competitions = const [];
  List<TeamItem> _teams = const [];
  final Set<int> _selectedCompetitionIds = {};
  final Set<int> _selectedTeamIds = {};

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.apiClient.getMyProfile(),
        widget.apiClient.getCompetitions(),
        widget.apiClient.getTeams(),
      ]);

      if (!mounted) {
        return;
      }

      final profile = results[0] as MeProfile;
      final competitions = (results[1] as List<CompetitionItem>)
          .where((item) => item.active)
          .toList();
      final teams = (results[2] as List<TeamItem>)
          .where((item) => item.active)
          .toList();

      _applyProfile(profile);
      setState(() {
        _competitions = competitions;
        _teams = teams;
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
        _errorMessage = 'No se pudo cargar el perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyProfile(MeProfile profile) {
    _profile = profile;
    _nameController.text = profile.name;
    _lastnameController.text = profile.lastname;
    _bioController.text = profile.bio ?? '';
    _selectedCompetitionIds
      ..clear()
      ..addAll(profile.preferredCompetitions.map((item) => item.id));
    _selectedTeamIds
      ..clear()
      ..addAll(profile.preferredTeams.map((item) => item.id));
  }

  List<TeamItem> get _visibleTeams {
    if (_selectedCompetitionIds.isEmpty) {
      return _teams;
    }
    return _teams
        .where((team) => _selectedCompetitionIds.contains(team.competitionId))
        .toList();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final updated = await widget.apiClient.updateMyProfile(
        name: _nameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        bio: _bioController.text.trim(),
        preferredCompetitionIds: _selectedCompetitionIds.toList(),
        preferredTeamIds: _selectedTeamIds.toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applyProfile(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado.')),
      );
      Navigator.of(context).pop(true);
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
        const SnackBar(content: Text('No se pudieron guardar los cambios.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final fullName = [
      _nameController.text.trim(),
      _lastnameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final initials = (fullName.isNotEmpty ? fullName : profile.username)
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Form(
        key: _formKey,
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
                        _ProfileAvatar(
                          avatarUrl: profile.avatarUrl,
                          initials: initials.isEmpty ? 'P' : initials,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Editar perfil', style: theme.textTheme.headlineMedium),
                              const SizedBox(height: 6),
                              Text('@${profile.username}', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(profile.email),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  final updated = await navigator.push<MeProfile>(
                                    MaterialPageRoute(
                                      builder: (context) => ProfileAvatarScreen(
                                        apiClient: widget.apiClient,
                                        profile: profile,
                                      ),
                                    ),
                                  );

                                  if (!mounted) {
                                    return;
                                  }

                                  if (updated != null) {
                                    setState(() {
                                      _applyProfile(updated);
                                    });
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Avatar actualizado.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.photo_camera_back_outlined),
                                label: const Text('Cambiar foto'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _bioController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText:
                            'Cuéntale a la comunidad tu enfoque, estilo o especialidad.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Escribe tu nombre.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastnameController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Escribe tu apellido.' : null,
                    ),
                    const SizedBox(height: 22),
                    Text('Competiciones favoritas', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _competitions.map((item) {
                        return FilterChip(
                          selected: _selectedCompetitionIds.contains(item.id),
                          label: Text(item.name),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCompetitionIds.add(item.id);
                              } else {
                                _selectedCompetitionIds.remove(item.id);
                                _selectedTeamIds.removeWhere(
                                  (teamId) => _teams.any(
                                    (team) => team.id == teamId && team.competitionId == item.id,
                                  ),
                                );
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    Text('Equipos favoritos', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _visibleTeams.map((item) {
                        return FilterChip(
                          selected: _selectedTeamIds.contains(item.id),
                          label: Text(item.name),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTeamIds.add(item.id);
                                _selectedCompetitionIds.add(item.competitionId);
                              } else {
                                _selectedTeamIds.remove(item.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios'),
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

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.initials,
  });

  final String? avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PickadosColors>()!;

    return Container(
      height: 84,
      width: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: avatarUrl == null
            ? LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, colors.danger],
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: avatarUrl != null
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.blueSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
