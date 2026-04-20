class DeepLinkTarget {
  const DeepLinkTarget._({
    required this.kind,
    this.postId,
    this.commentId,
    this.userId,
  });

  const DeepLinkTarget.post({
    required int postId,
    int? commentId,
  }) : this._(
          kind: DeepLinkTargetKind.post,
          postId: postId,
          commentId: commentId,
        );

  const DeepLinkTarget.profile({
    required int userId,
  }) : this._(
          kind: DeepLinkTargetKind.profile,
          userId: userId,
        );

  final DeepLinkTargetKind kind;
  final int? postId;
  final int? commentId;
  final int? userId;
}

enum DeepLinkTargetKind {
  post,
  profile,
}
