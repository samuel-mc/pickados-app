import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/notification_models.dart';
import '../../services/api_client.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  static const _pollInterval = Duration(seconds: 30);

  final ApiClient _apiClient;
  Timer? _timer;
  bool _loading = false;
  int _unreadCount = 0;
  List<NotificationItem> _items = const [];

  bool get loading => _loading;
  int get unreadCount => _unreadCount;
  List<NotificationItem> get items => _items;

  Future<void> initialize() async {
    await load();
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) {
      load(silent: true);
    });
  }

  Future<void> load({
    bool silent = false,
  }) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.getNotifications();
      _items = response.items;
      _unreadCount = response.unreadCount;
    } catch (_) {
      if (!silent) {
        rethrow;
      }
    } finally {
      if (!silent) {
        _loading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiClient.markNotificationAsRead(notificationId);
    _items = _items
        .map(
          (item) => item.id == notificationId ? item.copyWith(read: true) : item,
        )
        .toList();
    _unreadCount = _items.where((item) => !item.read).length;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
