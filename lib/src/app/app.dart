import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../features/auth/session_controller.dart';
import '../features/auth/ui/auth_flow_screen.dart';
import '../features/deeplinks/deep_link_controller.dart';
import '../features/home/ui/home_screen.dart';
import '../services/api_client.dart';
import 'app_theme.dart';

void runPickadosApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PickadosApp());
}

class PickadosApp extends StatefulWidget {
  const PickadosApp({super.key});

  @override
  State<PickadosApp> createState() => _PickadosAppState();
}

class _PickadosAppState extends State<PickadosApp> {
  late final ApiClient _apiClient;
  late final SessionController _sessionController;
  late final DeepLinkController _deepLinkController;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    _sessionController = SessionController(apiClient: _apiClient);
    _deepLinkController = DeepLinkController();
    _sessionController.initialize();
    _deepLinkController.initialize();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _deepLinkController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Pickados',
      theme: buildPickadosTheme(Brightness.light),
      darkTheme: buildPickadosTheme(Brightness.dark),
      themeMode: _themeMode,
      home: AnimatedBuilder(
        animation: Listenable.merge([_sessionController, _deepLinkController]),
        builder: (context, _) {
          switch (_sessionController.status) {
            case SessionStatus.loading:
              return SplashScreen(apiBaseUrl: AppConfig.apiBaseUrl);
            case SessionStatus.unauthenticated:
              return AuthFlowScreen(
                apiClient: _apiClient,
                sessionController: _sessionController,
                deepLinkController: _deepLinkController,
              );
            case SessionStatus.authenticated:
              return HomeScreen(
                apiClient: _apiClient,
                sessionController: _sessionController,
                deepLinkController: _deepLinkController,
                themeMode: _themeMode,
                onToggleThemeMode: _toggleThemeMode,
              );
          }
        },
      ),
    );
  }

  void _toggleThemeMode() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.dark => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.system => ThemeMode.dark,
      };
    });
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.apiBaseUrl});

  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.pageGradientTop, colors.pageGradientBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7CF6), Color(0xFFFF7A45)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Pickados App', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Inicializando sesion y preparando el feed desde la plataforma web existente.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('API: $apiBaseUrl', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
