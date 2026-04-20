import 'deep_link_target.dart';

class DeepLinkParser {
  const DeepLinkParser._();

  static DeepLinkTarget? parse(Uri uri) {
    final segments = _normalizedSegments(uri);
    if (segments.isEmpty) {
      return null;
    }

    if (segments.length >= 2 && segments[0] == 'posts') {
      final postId = int.tryParse(segments[1]);
      if (postId == null) {
        return null;
      }
      final commentId = int.tryParse(uri.queryParameters['commentId'] ?? '');
      return DeepLinkTarget.post(
        postId: postId,
        commentId: commentId,
      );
    }

    if (segments.length >= 2 &&
        (segments[0] == 'perfil' ||
            (segments[0] == 'tipster' && segments[1] == 'perfil'))) {
      final targetIndex = segments[0] == 'tipster' ? 2 : 1;
      if (segments.length <= targetIndex) {
        return null;
      }
      final userId = int.tryParse(segments[targetIndex]);
      if (userId == null) {
        return null;
      }
      return DeepLinkTarget.profile(userId: userId);
    }

    return null;
  }

  static List<String> _normalizedSegments(Uri uri) {
    final pathSegments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

    if (uri.scheme == 'pickados' && uri.host.isNotEmpty) {
      return [uri.host, ...pathSegments];
    }

    return pathSegments;
  }
}
