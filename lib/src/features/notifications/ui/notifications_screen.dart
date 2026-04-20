import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/notification_models.dart';
import '../../notifications/notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.controller,
    required this.onOpenNotification,
  });

  final NotificationsController controller;
  final Future<void> Function(NotificationItem notification) onOpenNotification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.loading && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Todavia no tienes notificaciones.'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = controller.items[index];
                return Card(
                  color: notification.read
                      ? null
                      : const Color(0xFFEFF6FD),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () async {
                      await onOpenNotification(notification);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NotificationAvatar(actor: notification.actor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '@${notification.actor.username}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (!notification.read)
                                      Container(
                                        height: 10,
                                        width: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFED5F2F),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(notification.message),
                                const SizedBox(height: 8),
                                Text(
                                  _formatNotificationDate(notification.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatNotificationDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) {
      return value;
    }

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return 'Hace $minutes min';
    }

    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    }

    if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} d';
    }

    return DateFormat('dd MMM').format(date);
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.actor,
  });

  final NotificationActor actor;

  @override
  Widget build(BuildContext context) {
    final initials = actor.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: actor.avatarUrl == null
            ? const LinearGradient(
                colors: [Color(0xFF0F4C81), Color(0xFFED5F2F)],
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: actor.avatarUrl != null
          ? Image.network(
              actor.avatarUrl!,
              fit: BoxFit.cover,
            )
          : Text(
              initials.isEmpty ? 'PK' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
