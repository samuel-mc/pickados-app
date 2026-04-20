class NotificationActor {
  NotificationActor({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.validatedTipster,
    required this.badge,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      validatedTipster: json['validatedTipster'] == true,
      badge: json['badge']?.toString(),
    );
  }

  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool validatedTipster;
  final String? badge;
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.read,
    required this.extraActorsCount,
    required this.postId,
    required this.commentId,
    required this.targetUserId,
    required this.actor,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      read: json['read'] == true,
      extraActorsCount: (json['extraActorsCount'] as num?)?.toInt() ?? 0,
      postId: (json['postId'] as num?)?.toInt(),
      commentId: (json['commentId'] as num?)?.toInt(),
      targetUserId: (json['targetUserId'] as num?)?.toInt(),
      actor: NotificationActor.fromJson(
        Map<String, dynamic>.from((json['actor'] as Map?) ?? const {}),
      ),
    );
  }

  final int id;
  final String type;
  final String message;
  final String createdAt;
  final bool read;
  final int extraActorsCount;
  final int? postId;
  final int? commentId;
  final int? targetUserId;
  final NotificationActor actor;

  NotificationItem copyWith({
    bool? read,
  }) {
    return NotificationItem(
      id: id,
      type: type,
      message: message,
      createdAt: createdAt,
      read: read ?? this.read,
      extraActorsCount: extraActorsCount,
      postId: postId,
      commentId: commentId,
      targetUserId: targetUserId,
      actor: actor,
    );
  }
}

class NotificationListResponse {
  NotificationListResponse({
    required this.unreadCount,
    required this.items,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return NotificationListResponse(
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => NotificationItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
    );
  }

  final int unreadCount;
  final List<NotificationItem> items;
}
