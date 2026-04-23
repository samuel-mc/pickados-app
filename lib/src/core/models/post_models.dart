enum ReactionType {
  like('LIKE'),
  dislike('DISLIKE');

  const ReactionType(this.apiValue);

  final String apiValue;
}

enum PostType {
  analysis('ANALYSIS'),
  pickSimple('PICK_SIMPLE'),
  parley('PARLEY');

  const PostType(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case PostType.analysis:
        return 'Analisis';
      case PostType.pickSimple:
        return 'Pick simple';
      case PostType.parley:
        return 'Parley';
    }
  }
}

enum PostVisibility {
  public('PUBLIC'),
  followersOnly('FOLLOWERS_ONLY'),
  private('PRIVATE');

  const PostVisibility(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case PostVisibility.public:
        return 'Publico';
      case PostVisibility.followersOnly:
        return 'Solo seguidores';
      case PostVisibility.private:
        return 'Privado';
    }
  }
}

enum ResultStatus {
  pending('PENDING'),
  won('WON'),
  lost('LOST'),
  voided('VOID');

  const ResultStatus(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case ResultStatus.pending:
        return 'Pendiente';
      case ResultStatus.won:
        return 'Ganado';
      case ResultStatus.lost:
        return 'Perdido';
      case ResultStatus.voided:
        return 'Void';
    }
  }
}

class PostAuthor {
  PostAuthor({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.validatedTipster,
    required this.followedByCurrentUser,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      validatedTipster: json['validatedTipster'] == true,
      followedByCurrentUser: json['followedByCurrentUser'] == true,
    );
  }

  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool validatedTipster;
  final bool followedByCurrentUser;

  PostAuthor copyWith({
    String? name,
    String? username,
    String? avatarUrl,
    bool? validatedTipster,
    bool? followedByCurrentUser,
  }) {
    return PostAuthor(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      validatedTipster: validatedTipster ?? this.validatedTipster,
      followedByCurrentUser:
          followedByCurrentUser ?? this.followedByCurrentUser,
    );
  }
}

class PostMetrics {
  PostMetrics({
    required this.commentsCount,
    required this.likesCount,
    required this.dislikesCount,
    required this.viewsCount,
    required this.savesCount,
    required this.sharesCount,
    required this.repostsCount,
    required this.savedByCurrentUser,
    required this.repostedByCurrentUser,
    required this.currentUserReaction,
  });

  factory PostMetrics.fromJson(Map<String, dynamic> json) {
    return PostMetrics(
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikesCount'] as num?)?.toInt() ?? 0,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      savesCount: (json['savesCount'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      repostsCount: (json['repostsCount'] as num?)?.toInt() ?? 0,
      savedByCurrentUser: json['savedByCurrentUser'] == true,
      repostedByCurrentUser: json['repostedByCurrentUser'] == true,
      currentUserReaction: (json['currentUserReaction'] ?? '').toString(),
    );
  }

  final int commentsCount;
  final int likesCount;
  final int dislikesCount;
  final int viewsCount;
  final int savesCount;
  final int sharesCount;
  final int repostsCount;
  final bool savedByCurrentUser;
  final bool repostedByCurrentUser;
  final String currentUserReaction;

  PostMetrics copyWith({
    int? commentsCount,
    int? likesCount,
    int? dislikesCount,
    int? viewsCount,
    int? savesCount,
    int? sharesCount,
    int? repostsCount,
    bool? savedByCurrentUser,
    bool? repostedByCurrentUser,
    String? currentUserReaction,
  }) {
    return PostMetrics(
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      savesCount: savesCount ?? this.savesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      savedByCurrentUser: savedByCurrentUser ?? this.savedByCurrentUser,
      repostedByCurrentUser:
          repostedByCurrentUser ?? this.repostedByCurrentUser,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
    );
  }
}

class PickSummary {
  PickSummary({
    required this.sport,
    required this.league,
    required this.stake,
    required this.resultStatus,
    this.eventDate,
    this.sportsbookName,
    this.sportsbookBaseUrl,
    this.sportsbookLogoUrl,
  });

  factory PickSummary.fromJson(Map<String, dynamic> json) {
    final sportsbook = json['sportsbook'];
    final sportsbookMap = sportsbook is Map
        ? Map<String, dynamic>.from(sportsbook)
        : const <String, dynamic>{};

    return PickSummary(
      sport: (json['sport'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      stake: (json['stake'] as num?)?.toDouble() ?? 0,
      resultStatus: (json['resultStatus'] ?? 'PENDING').toString(),
      eventDate: json['eventDate']?.toString(),
      sportsbookName: sportsbookMap['name']?.toString(),
      sportsbookBaseUrl: sportsbookMap['baseUrl']?.toString(),
      sportsbookLogoUrl: sportsbookMap['logoUrl']?.toString(),
    );
  }

  final String sport;
  final String league;
  final double stake;
  final String resultStatus;
  final String? eventDate;
  final String? sportsbookName;
  final String? sportsbookBaseUrl;
  final String? sportsbookLogoUrl;

  PickSummary copyWith({String? resultStatus}) {
    return PickSummary(
      sport: sport,
      league: league,
      stake: stake,
      resultStatus: resultStatus ?? this.resultStatus,
      eventDate: eventDate,
      sportsbookName: sportsbookName,
      sportsbookBaseUrl: sportsbookBaseUrl,
      sportsbookLogoUrl: sportsbookLogoUrl,
    );
  }
}

class ParleySummary {
  ParleySummary({
    required this.stake,
    required this.resultStatus,
    this.eventDate,
    this.sportsbookName,
    this.sportsbookBaseUrl,
    this.sportsbookLogoUrl,
  });

  factory ParleySummary.fromJson(Map<String, dynamic> json) {
    final sportsbook = json['sportsbook'];
    final sportsbookMap = sportsbook is Map
        ? Map<String, dynamic>.from(sportsbook)
        : const <String, dynamic>{};

    return ParleySummary(
      stake: (json['stake'] as num?)?.toDouble() ?? 0,
      resultStatus: (json['resultStatus'] ?? 'PENDING').toString(),
      eventDate: json['eventDate']?.toString(),
      sportsbookName: sportsbookMap['name']?.toString(),
      sportsbookBaseUrl: sportsbookMap['baseUrl']?.toString(),
      sportsbookLogoUrl: sportsbookMap['logoUrl']?.toString(),
    );
  }

  final double stake;
  final String resultStatus;
  final String? eventDate;
  final String? sportsbookName;
  final String? sportsbookBaseUrl;
  final String? sportsbookLogoUrl;

  ParleySummary copyWith({String? resultStatus}) {
    return ParleySummary(
      stake: stake,
      resultStatus: resultStatus ?? this.resultStatus,
      eventDate: eventDate,
      sportsbookName: sportsbookName,
      sportsbookBaseUrl: sportsbookBaseUrl,
      sportsbookLogoUrl: sportsbookLogoUrl,
    );
  }
}

class ParleySelectionSummary {
  ParleySelectionSummary({
    required this.id,
    required this.sport,
    required this.league,
  });

  factory ParleySelectionSummary.fromJson(Map<String, dynamic> json) {
    return ParleySelectionSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sport: (json['sport'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
    );
  }

  final int id;
  final String sport;
  final String league;
}

class CommentItem {
  CommentItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    required this.parentCommentId,
    required this.replyingToUsername,
    required this.likesCount,
    required this.likedByCurrentUser,
    required this.replies,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];

    return CommentItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: (json['content'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      author: PostAuthor.fromJson(
        Map<String, dynamic>.from((json['author'] as Map?) ?? const {}),
      ),
      parentCommentId: (json['parentCommentId'] as num?)?.toInt(),
      replyingToUsername: json['replyingToUsername']?.toString(),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      likedByCurrentUser: json['likedByCurrentUser'] == true,
      replies: rawReplies is List
          ? rawReplies
                .whereType<Map>()
                .map(
                  (item) =>
                      CommentItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
    );
  }

  final int id;
  final String content;
  final String createdAt;
  final PostAuthor author;
  final int? parentCommentId;
  final String? replyingToUsername;
  final int likesCount;
  final bool likedByCurrentUser;
  final List<CommentItem> replies;

  CommentItem copyWith({
    String? content,
    String? createdAt,
    PostAuthor? author,
    int? parentCommentId,
    String? replyingToUsername,
    int? likesCount,
    bool? likedByCurrentUser,
    List<CommentItem>? replies,
  }) {
    return CommentItem(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyingToUsername: replyingToUsername ?? this.replyingToUsername,
      likesCount: likesCount ?? this.likesCount,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      replies: replies ?? this.replies,
    );
  }
}

class CreateSimplePickPayload {
  CreateSimplePickPayload({
    required this.sportId,
    required this.leagueId,
    required this.stake,
    required this.eventDate,
    required this.resultStatus,
    this.sportsbookId,
  });

  final int sportId;
  final int leagueId;
  final int stake;
  final String eventDate;
  final ResultStatus resultStatus;
  final int? sportsbookId;

  Map<String, dynamic> toJson() {
    return {
      'sportId': sportId,
      'leagueId': leagueId,
      'stake': stake,
      'sportsbookId': sportsbookId,
      'eventDate': eventDate,
      'resultStatus': resultStatus.apiValue,
    };
  }
}

class CreateParleySelectionPayload {
  CreateParleySelectionPayload({required this.sportId, required this.leagueId});

  final int sportId;
  final int leagueId;

  Map<String, dynamic> toJson() {
    return {'sportId': sportId, 'leagueId': leagueId};
  }
}

class CreateParleyPayload {
  CreateParleyPayload({
    required this.stake,
    required this.eventDate,
    required this.resultStatus,
    required this.selections,
    this.sportsbookId,
  });

  final int stake;
  final String eventDate;
  final ResultStatus resultStatus;
  final List<CreateParleySelectionPayload> selections;
  final int? sportsbookId;

  Map<String, dynamic> toJson() {
    return {
      'stake': stake,
      'sportsbookId': sportsbookId,
      'eventDate': eventDate,
      'resultStatus': resultStatus.apiValue,
      'selections': selections.map((item) => item.toJson()).toList(),
    };
  }
}

class CreatePostPayload {
  CreatePostPayload({
    required this.type,
    required this.content,
    required this.tags,
    required this.visibility,
    this.imageKey,
    this.simplePick,
    this.parley,
  });

  final PostType type;
  final String content;
  final List<String> tags;
  final PostVisibility visibility;
  final String? imageKey;
  final CreateSimplePickPayload? simplePick;
  final CreateParleyPayload? parley;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'content': content,
      'tags': tags,
      'visibility': visibility.apiValue,
      if (imageKey != null) 'imageKey': imageKey,
      if (simplePick != null) 'simplePick': simplePick!.toJson(),
      if (parley != null) 'parley': parley!.toJson(),
    };
  }
}

class PostItem {
  PostItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
    required this.author,
    required this.mediaUrls,
    required this.tags,
    required this.metrics,
    required this.simplePick,
    required this.parley,
    required this.parleySelections,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final media = json['mediaUrls'];
    final tags = json['tags'];
    final rawPick = json['simplePick'];
    final rawParley = json['parley'];
    final rawParleySelections = json['parleySelections'];

    return PostItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: (json['content'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      author: PostAuthor.fromJson(
        Map<String, dynamic>.from((json['author'] as Map?) ?? const {}),
      ),
      mediaUrls: media is List ? media.map((e) => e.toString()).toList() : [],
      tags: tags is List ? tags.map((e) => e.toString()).toList() : [],
      metrics: PostMetrics.fromJson(
        Map<String, dynamic>.from((json['metrics'] as Map?) ?? const {}),
      ),
      simplePick: rawPick is Map
          ? PickSummary.fromJson(Map<String, dynamic>.from(rawPick))
          : null,
      parley: rawParley is Map
          ? ParleySummary.fromJson(Map<String, dynamic>.from(rawParley))
          : null,
      parleySelections: rawParleySelections is List
          ? rawParleySelections
                .whereType<Map>()
                .map(
                  (item) => ParleySelectionSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }

  final int id;
  final String content;
  final String createdAt;
  final String type;
  final PostAuthor author;
  final List<String> mediaUrls;
  final List<String> tags;
  final PostMetrics metrics;
  final PickSummary? simplePick;
  final ParleySummary? parley;
  final List<ParleySelectionSummary> parleySelections;

  PostItem copyWith({
    PostAuthor? author,
    PostMetrics? metrics,
    PickSummary? simplePick,
    ParleySummary? parley,
  }) {
    return PostItem(
      id: id,
      content: content,
      createdAt: createdAt,
      type: type,
      author: author ?? this.author,
      mediaUrls: mediaUrls,
      tags: tags,
      metrics: metrics ?? this.metrics,
      simplePick: simplePick ?? this.simplePick,
      parley: parley ?? this.parley,
      parleySelections: parleySelections,
    );
  }

  String get currentResultStatus =>
      simplePick?.resultStatus ?? parley?.resultStatus ?? 'PENDING';

  bool get hasStructuredBet => simplePick != null || parley != null;
}
