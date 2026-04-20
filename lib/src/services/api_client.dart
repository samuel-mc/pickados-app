import 'dart:convert';
import 'dart:io';

import '../core/models/api_response.dart';
import '../core/models/auth_session.dart';
import '../core/models/post_models.dart';
import '../core/models/profile_models.dart';
import '../core/models/catalog_models.dart';
import '../core/models/notification_models.dart';

class ApiClient {
  ApiClient({required this.baseUrl}) : _httpClient = HttpClient();

  final String baseUrl;
  final HttpClient _httpClient;
  final Map<String, String> _cookies = {};

  File get _sessionFile =>
      File('${Directory.systemTemp.path}/pickados_mobile_session.json');

  Future<void> initialize() async {
    if (!await _sessionFile.exists()) {
      return;
    }

    try {
      final raw = await _sessionFile.readAsString();
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        final savedCookies = json['cookies'];
        if (savedCookies is Map) {
          _cookies
            ..clear()
            ..addAll(
              savedCookies.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
        }
      }
    } catch (_) {
      await clearSession();
    }
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    await _send(
      'POST',
      '/auth/login',
      body: {'username': username, 'password': password},
    );
    return getSession();
  }

  Future<AuthAvailabilityResult> checkAvailability({
    required String username,
    required String email,
  }) async {
    final json = await _send(
      'GET',
      '/auth/availability',
      queryParameters: {'username': username, 'email': email},
    );

    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );

    return AuthAvailabilityResult(
      usernameAvailable: envelope.data['usernameAvailable'] != false,
      emailAvailable: envelope.data['emailAvailable'] != false,
    );
  }

  Future<void> registerTipster({
    required String name,
    required String lastname,
    required String username,
    required String email,
    required String password,
    required String birthDate,
    required String bio,
  }) async {
    await _send(
      'POST',
      '/auth/register-tipster',
      body: {
        'name': name.trim().toUpperCase(),
        'lastname': lastname.trim().toUpperCase(),
        'username': username.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'birthDate': birthDate,
        'bio': bio.trim(),
        'avatarUrl': '/register-tipster',
      },
    );
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _send(
      'POST',
      '/auth/request-password-reset',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _send(
      'POST',
      '/auth/reset-password',
      body: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> verifyEmail({required String token}) async {
    await _send('GET', '/auth/verify-email', queryParameters: {'token': token});
  }

  Future<AuthSession> getSession() async {
    final json = await _send('GET', '/auth/session');
    return AuthSession.fromJson(json);
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/auth/logout');
    } finally {
      await clearSession();
    }
  }

  Future<PagedResponse<PostItem>> getFeed({
    required bool savedOnly,
    int page = 0,
    int size = 10,
    int? authorId,
  }) async {
    final path = savedOnly
        ? '/posts/saved'
        : authorId != null
        ? '/posts/users/$authorId'
        : '/posts/feed';
    final json = await _send(
      'GET',
      path,
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => PagedResponse.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
        PostItem.fromJson,
      ),
    );

    return envelope.data;
  }

  Future<PostItem> getPostDetail(int postId) async {
    final json = await _send('GET', '/posts/$postId');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => PostItem.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
      ),
    );
    return envelope.data;
  }

  Future<void> registerView(int postId) async {
    await _send('POST', '/posts/$postId/views');
  }

  Future<List<CommentItem>> getComments(int postId) async {
    final json = await _send('GET', '/posts/$postId/comments');
    final envelope = ApiEnvelope.fromJson(json, (raw) {
      if (raw is! List) {
        return <CommentItem>[];
      }
      return raw
          .whereType<Map>()
          .map((item) => CommentItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
    return envelope.data;
  }

  Future<CommentItem> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    final json = await _send(
      'POST',
      '/posts/$postId/comments',
      body: {'content': content, 'parentCommentId': parentCommentId},
    );
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => CommentItem.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
      ),
    );
    return envelope.data;
  }

  Future<CommentItem> toggleCommentLike({
    required int postId,
    required int commentId,
  }) async {
    final json = await _send('PUT', '/posts/$postId/comments/$commentId/like');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => CommentItem.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
      ),
    );
    return envelope.data;
  }

  Future<PostItem> createPost(CreatePostPayload payload) async {
    final json = await _send('POST', '/posts', body: payload.toJson());
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => PostItem.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
      ),
    );
    return envelope.data;
  }

  Future<PostItem> updatePickStatus({
    required int postId,
    required ResultStatus status,
  }) async {
    final json = await _send(
      'PUT',
      '/posts/$postId/pick-status',
      body: {'resultStatus': status.apiValue},
    );
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => PostItem.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
      ),
    );
    return envelope.data;
  }

  Future<PostMediaUploadResult> uploadPostImage({
    required List<int> bytes,
    required String contentType,
  }) async {
    final presignJson = await _send(
      'POST',
      '/posts/media/presign',
      body: {'contentType': contentType},
    );

    final uploadUrl = (presignJson['uploadUrl'] ?? '').toString();
    final objectKey = (presignJson['objectKey'] ?? '').toString();

    if (uploadUrl.isEmpty || objectKey.isEmpty) {
      throw ApiException(
        statusCode: 500,
        message: 'No se pudo preparar la subida de imagen.',
      );
    }

    final uploadRequest = await _httpClient.openUrl(
      'PUT',
      Uri.parse(uploadUrl),
    );
    uploadRequest.headers.set(HttpHeaders.contentTypeHeader, contentType);
    uploadRequest.add(bytes);
    final uploadResponse = await uploadRequest.close();
    await uploadResponse.drain();

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ApiException(
        statusCode: uploadResponse.statusCode,
        message: 'No se pudo subir la imagen al almacenamiento.',
      );
    }

    final completeJson = await _send(
      'POST',
      '/posts/media/complete',
      body: {'objectKey': objectKey},
    );

    final envelope = ApiEnvelope.fromJson(
      completeJson,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );

    return PostMediaUploadResult(
      objectKey: (envelope.data['objectKey'] ?? '').toString(),
      mediaUrl: (envelope.data['mediaUrl'] ?? '').toString(),
    );
  }

  Future<List<CatalogItem>> getSports() async {
    final json = await _send('GET', '/catalogs/sports');
    final envelope = ApiEnvelope.fromJson(json, (raw) {
      if (raw is! List) {
        return <CatalogItem>[];
      }
      return raw
          .whereType<Map>()
          .map((item) => CatalogItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
    return envelope.data;
  }

  Future<List<CompetitionItem>> getCompetitions() async {
    final json = await _send('GET', '/catalogs/competitions');
    final envelope = ApiEnvelope.fromJson(json, (raw) {
      if (raw is! List) {
        return <CompetitionItem>[];
      }
      return raw
          .whereType<Map>()
          .map(
            (item) => CompetitionItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    });
    return envelope.data;
  }

  Future<List<TeamItem>> getTeams() async {
    final json = await _send('GET', '/catalogs/teams');
    final envelope = ApiEnvelope.fromJson(json, (raw) {
      if (raw is! List) {
        return <TeamItem>[];
      }
      return raw
          .whereType<Map>()
          .map((item) => TeamItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
    return envelope.data;
  }

  Future<List<SportsbookItem>> getSportsbooks() async {
    final json = await _send('GET', '/sportsbooks');
    final envelope = ApiEnvelope.fromJson(json, (raw) {
      if (raw is! List) {
        return <SportsbookItem>[];
      }
      return raw
          .whereType<Map>()
          .map(
            (item) => SportsbookItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    });
    return envelope.data;
  }

  Future<MeProfile> getMyProfile() async {
    final json = await _send('GET', '/me/profile');
    return MeProfile.fromJson(json);
  }

  Future<MeProfile> updateMyProfile({
    required String name,
    required String lastname,
    required String bio,
    required List<int> preferredCompetitionIds,
    required List<int> preferredTeamIds,
  }) async {
    final json = await _send(
      'PUT',
      '/me/profile',
      body: {
        'name': name,
        'lastname': lastname,
        'bio': bio,
        'preferredCompetitionIds': preferredCompetitionIds,
        'preferredTeamIds': preferredTeamIds,
      },
    );
    return MeProfile.fromJson(json);
  }

  Future<MeProfile> uploadProfileAvatar({
    required List<int> bytes,
    required String contentType,
  }) async {
    final presignJson = await _send(
      'POST',
      '/me/profile/avatar/presign',
      body: {'contentType': contentType},
    );

    final uploadUrl = (presignJson['uploadUrl'] ?? '').toString();
    final objectKey = (presignJson['objectKey'] ?? '').toString();

    if (uploadUrl.isEmpty || objectKey.isEmpty) {
      throw ApiException(
        statusCode: 500,
        message: 'No se pudo preparar la subida del avatar.',
      );
    }

    final uploadRequest = await _httpClient.openUrl(
      'PUT',
      Uri.parse(uploadUrl),
    );
    uploadRequest.headers.set(HttpHeaders.contentTypeHeader, contentType);
    uploadRequest.add(bytes);
    final uploadResponse = await uploadRequest.close();
    await uploadResponse.drain();

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ApiException(
        statusCode: uploadResponse.statusCode,
        message: 'No se pudo subir la imagen del avatar.',
      );
    }

    final completeJson = await _send(
      'POST',
      '/me/profile/avatar/complete',
      body: {'objectKey': objectKey},
    );

    return MeProfile.fromJson(completeJson);
  }

  Future<PublicProfile> getPublicProfile(int userId) async {
    final json = await _send('GET', '/users/$userId/profile');
    return PublicProfile.fromJson(json);
  }

  Future<PagedResponse<PostItem>> getPostsByUser(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    final json = await _send(
      'GET',
      '/posts/users/$userId',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => PagedResponse.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
        PostItem.fromJson,
      ),
    );
    return envelope.data;
  }

  Future<bool> followUser(int userId) async {
    final json = await _send('POST', '/posts/users/$userId/follow');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );
    return envelope.data['active'] == true;
  }

  Future<bool> unfollowUser(int userId) async {
    final json = await _send('DELETE', '/posts/users/$userId/follow');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );
    return envelope.data['active'] == true;
  }

  Future<NotificationListResponse> getNotifications() async {
    final json = await _send('GET', '/notifications');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => NotificationListResponse.fromJson(
        Map<String, dynamic>.from((raw as Map?) ?? const {}),
      ),
    );
    return envelope.data;
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _send('PUT', '/notifications/$notificationId/read');
  }

  Future<bool> toggleSave(int postId) async {
    final json = await _send('PUT', '/posts/$postId/save');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );
    return envelope.data['active'] == true;
  }

  Future<PostMetrics> toggleReaction(int postId, ReactionType reaction) async {
    final json = await _send(
      'PUT',
      '/posts/$postId/reaction',
      body: {'type': reaction.apiValue},
    );
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );
    return PostMetrics.fromJson(envelope.data);
  }

  Future<bool> toggleRepost(int postId) async {
    final json = await _send('PUT', '/posts/$postId/repost');
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );
    return envelope.data['active'] == true;
  }

  Future<PostMetrics> registerShare({
    required int postId,
    required String channel,
  }) async {
    final json = await _send(
      'POST',
      '/posts/$postId/share',
      body: {'channel': channel},
    );
    final envelope = ApiEnvelope.fromJson(
      json,
      (raw) => Map<String, dynamic>.from((raw as Map?) ?? const {}),
    );
    return PostMetrics.fromJson(envelope.data);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);
    final request = await _httpClient.openUrl(method, uri);

    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    if (_cookies.isNotEmpty) {
      request.headers.set(
        HttpHeaders.cookieHeader,
        _cookies.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('; '),
      );
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    _captureCookies(response.headers);
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) {
        return <String, dynamic>{};
      }
      return jsonDecode(responseBody);
    }

    if (response.statusCode == 401) {
      await clearSession();
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(responseBody),
    );
  }

  String _extractErrorMessage(String body) {
    if (body.isEmpty) {
      return 'No fue posible completar la solicitud.';
    }

    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final message = json['message'] ?? json['error'];
        if (message != null) {
          return message.toString();
        }
      }
    } catch (_) {
      return body;
    }

    return body;
  }

  void _captureCookies(HttpHeaders headers) {
    final setCookies = headers[HttpHeaders.setCookieHeader];
    if (setCookies == null || setCookies.isEmpty) {
      return;
    }

    for (final rawCookie in setCookies) {
      final cookie = Cookie.fromSetCookieValue(rawCookie);
      _cookies[cookie.name] = cookie.value;
    }

    _persistCookies();
  }

  Future<void> _persistCookies() async {
    await _sessionFile.writeAsString(jsonEncode({'cookies': _cookies}));
  }

  Future<void> clearSession() async {
    _cookies.clear();
    if (await _sessionFile.exists()) {
      await _sessionFile.delete();
    }
  }

  void dispose() {
    _httpClient.close(force: true);
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class PostMediaUploadResult {
  PostMediaUploadResult({required this.objectKey, required this.mediaUrl});

  final String objectKey;
  final String mediaUrl;
}

class AuthAvailabilityResult {
  AuthAvailabilityResult({
    required this.usernameAvailable,
    required this.emailAvailable,
  });

  final bool usernameAvailable;
  final bool emailAvailable;
}
