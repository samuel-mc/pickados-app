import 'package:flutter/material.dart';

import '../../core/models/auth_session.dart';
import '../../services/api_client.dart';

enum SessionStatus {
  loading,
  authenticated,
  unauthenticated,
}

class SessionController extends ChangeNotifier {
  SessionController({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  SessionStatus _status = SessionStatus.loading;
  AuthSession? _session;
  String? _errorMessage;
  bool _isAuthenticating = false;

  SessionStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticating => _isAuthenticating;

  Future<void> initialize() async {
    _status = SessionStatus.loading;
    notifyListeners();

    await _apiClient.initialize();

    try {
      final session = await _apiClient.getSession();
      if (!session.isTipster) {
        await _apiClient.clearSession();
        _session = null;
        _status = SessionStatus.unauthenticated;
        _errorMessage = 'Esta app movil es exclusiva para cuentas tipster.';
        notifyListeners();
        return;
      }
      _session = session;
      _status = SessionStatus.authenticated;
      _errorMessage = null;
    } on ApiException {
      _session = null;
      _status = SessionStatus.unauthenticated;
    } catch (_) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = 'No se pudo conectar con la API.';
    }

    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _apiClient.login(
        username: username,
        password: password,
      );
      if (!session.isTipster) {
        await _apiClient.clearSession();
        _session = null;
        _status = SessionStatus.unauthenticated;
        _errorMessage = 'Solo las cuentas tipster pueden entrar a esta app.';
        return false;
      }
      _session = session;
      _status = SessionStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = 'No fue posible iniciar sesion. Revisa tu conexion con la API.';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _status = SessionStatus.loading;
    notifyListeners();

    await _apiClient.logout();
    _session = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}
