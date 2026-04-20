import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'deep_link_parser.dart';
import 'deep_link_target.dart';

class DeepLinkController extends ChangeNotifier {
  DeepLinkController() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  DeepLinkTarget? _pendingTarget;
  Uri? _pendingUri;

  DeepLinkTarget? get pendingTarget => _pendingTarget;
  Uri? get pendingUri => _pendingUri;

  Future<void> initialize() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _setPendingFromUri(initialUri);
      }
    } catch (_) {
      // Ignore malformed or unavailable initial links.
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _setPendingFromUri(uri);
      },
      onError: (_) {
        // Ignore stream errors and continue listening.
      },
    );
  }

  void _setPendingFromUri(Uri uri) {
    _pendingUri = uri;
    final target = DeepLinkParser.parse(uri);
    if (target != null) {
      _pendingTarget = target;
    }
    notifyListeners();
  }

  DeepLinkTarget? consumePendingTarget() {
    final target = _pendingTarget;
    _pendingTarget = null;
    _pendingUri = null;
    return target;
  }

  Uri? consumePendingUri() {
    final uri = _pendingUri;
    _pendingUri = null;
    return uri;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
