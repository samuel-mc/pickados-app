import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/notification_models.dart';
import '../../../services/api_client.dart';
import '../../auth/session_controller.dart';
import '../../deeplinks/deep_link_controller.dart';
import '../../deeplinks/deep_link_target.dart';
import '../../feed/feed_controller.dart';
import '../../feed/ui/feed_screen.dart';
import '../../notifications/notifications_controller.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../../profile/ui/public_profile_screen.dart';
import '../../posts/ui/create_post_screen.dart';
import '../../posts/ui/post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiClient,
    required this.sessionController,
    required this.deepLinkController,
    required this.themeMode,
    required this.onToggleThemeMode,
  });

  final ApiClient apiClient;
  final SessionController sessionController;
  final DeepLinkController deepLinkController;
  final ThemeMode themeMode;
  final VoidCallback onToggleThemeMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FeedController _feedController;
  late final FeedController _savedController;
  late final NotificationsController _notificationsController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _profileRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _feedController = FeedController(
      apiClient: widget.apiClient,
      savedOnly: false,
    );
    _savedController = FeedController(
      apiClient: widget.apiClient,
      savedOnly: true,
    );
    _notificationsController = NotificationsController(
      apiClient: widget.apiClient,
    );
    _notificationsController.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingDeepLink();
    });
  }

  @override
  void dispose() {
    _feedController.dispose();
    _savedController.dispose();
    _notificationsController.dispose();
    super.dispose();
  }

  Future<void> _consumePendingDeepLink() async {
    final target = widget.deepLinkController.consumePendingTarget();
    if (target == null || !mounted) {
      return;
    }

    await _openDeepLinkTarget(target);
  }

  Future<void> _openDeepLinkTarget(DeepLinkTarget target) async {
    switch (target.kind) {
      case DeepLinkTargetKind.post:
        if (target.postId == null || !mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => PostDetailScreen(
              apiClient: widget.apiClient,
              postId: target.postId!,
              currentUserId: widget.sessionController.session?.userId,
              highlightCommentId: target.commentId,
            ),
          ),
        );
        break;
      case DeepLinkTargetKind.profile:
        if (target.userId == null || !mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => PublicProfileScreen(
              apiClient: widget.apiClient,
              userId: target.userId!,
              currentUserId: widget.sessionController.session?.userId,
            ),
          ),
        );
        break;
    }
  }

  Future<void> _openNotification(NotificationItem notification) async {
    await _notificationsController.markAsRead(notification.id);
    if (!mounted) {
      return;
    }

    if (notification.type == 'FOLLOW_STARTED' &&
        notification.targetUserId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PublicProfileScreen(
            apiClient: widget.apiClient,
            userId: notification.targetUserId!,
            currentUserId: widget.sessionController.session?.userId,
          ),
        ),
      );
      return;
    }

    if (notification.postId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => PostDetailScreen(
            apiClient: widget.apiClient,
            postId: notification.postId!,
            currentUserId: widget.sessionController.session?.userId,
            highlightCommentId: notification.commentId,
          ),
        ),
      );
    }
  }

  Future<void> _openSavedPosts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<PickadosColors>()!.pageGradientBottom,
          appBar: AppBar(title: const Text('Guardados')),
          body: FeedScreen(
            apiClient: widget.apiClient,
            controller: _savedController,
            currentUserId: widget.sessionController.session?.userId,
            baseTitle: 'Guardados',
            baseSubtitle: 'Tus posts guardados en un solo lugar.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionController.session;
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingDeepLink();
    });

    final pages = [
      FeedScreen(
        apiClient: widget.apiClient,
        controller: _feedController,
        currentUserId: session?.userId,
        baseTitle: 'Feed principal',
        baseSubtitle:
            'Replica movil del timeline de Picka2 usando `/posts/feed`.',
      ),
      ProfileScreen(
        key: ValueKey(_profileRefreshTick),
        apiClient: widget.apiClient,
        sessionController: widget.sessionController,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.pageGradientBottom,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: colors.cardGlass,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: colors.cardGlass,
            border: Border(bottom: BorderSide(color: colors.borderSoft)),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pickados',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (session != null)
              Text(
                '@${session.username}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              onPressed: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => ProfileEditScreen(
                      apiClient: widget.apiClient,
                      sessionController: widget.sessionController,
                    ),
                  ),
                );
                if (updated == true && mounted) {
                  setState(() {
                    _profileRefreshTick += 1;
                  });
                }
              },
              tooltip: 'Editar perfil',
              icon: const Icon(Icons.edit_rounded),
            ),
          AnimatedBuilder(
            animation: _notificationsController,
            builder: (context, _) {
              final unreadCount = _notificationsController.unreadCount;
              return IconButton(
                onPressed: () async {
                  await _notificationsController.load();
                  if (!context.mounted) {
                    return;
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => NotificationsScreen(
                        controller: _notificationsController,
                        onOpenNotification: _openNotification,
                      ),
                    ),
                  );
                },
                tooltip: 'Notificaciones',
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              );
            },
          ),
          if (_currentIndex == 1)
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageGradientTop, colors.pageGradientBottom],
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final created = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreatePostScreen(apiClient: widget.apiClient),
                  ),
                );

                if (!context.mounted) {
                  return;
                }

                if (created != null) {
                  await _feedController.refresh();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Post publicado correctamente.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo post'),
            )
          : null,
      endDrawer: _SettingsDrawer(
        onOpenSaved: _openSavedPosts,
        themeMode: widget.themeMode,
        onToggleThemeMode: widget.onToggleThemeMode,
        onLogout: () {
          widget.sessionController.logout();
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.cardGlass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.borderSoft),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsDrawer extends StatelessWidget {
  const _SettingsDrawer({
    required this.onOpenSaved,
    required this.themeMode,
    required this.onToggleThemeMode,
    required this.onLogout,
  });

  final Future<void> Function() onOpenSaved;
  final ThemeMode themeMode;
  final VoidCallback onToggleThemeMode;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Menu', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configuracion', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bookmark_rounded),
                      title: const Text('Guardados'),
                      subtitle: const Text('Ver posts guardados'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await onOpenSaved();
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SwitchListTile.adaptive(
                        title: const Text('Modo oscuro'),
                        subtitle: Text(
                          themeMode == ThemeMode.dark
                              ? 'Activo'
                              : 'Desactivado',
                        ),
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) => onToggleThemeMode(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesion'),
            ),
          ],
        ),
      ),
    );
  }
}
