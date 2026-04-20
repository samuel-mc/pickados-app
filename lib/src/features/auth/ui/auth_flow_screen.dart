import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../services/api_client.dart';
import '../../deeplinks/deep_link_controller.dart';
import '../session_controller.dart';
import 'login_screen.dart';

enum AuthView {
  landing,
  login,
  signup,
  forgotPassword,
  resetPassword,
  verifyEmail,
}

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    required this.apiClient,
    required this.sessionController,
    required this.deepLinkController,
  });

  final ApiClient apiClient;
  final SessionController sessionController;
  final DeepLinkController deepLinkController;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  AuthView _currentView = AuthView.landing;
  String? _token;

  @override
  void initState() {
    super.initState();
    widget.deepLinkController.addListener(_handlePendingUri);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingUri();
    });
  }

  @override
  void dispose() {
    widget.deepLinkController.removeListener(_handlePendingUri);
    super.dispose();
  }

  void _handlePendingUri() {
    final uri = widget.deepLinkController.pendingUri;
    if (uri == null) {
      return;
    }

    final authIntent = _parseAuthIntent(uri);
    if (authIntent == null) {
      return;
    }

    widget.deepLinkController.consumePendingUri();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentView = authIntent.view;
      _token = authIntent.token;
    });
  }

  void _open(AuthView view, {String? token}) {
    setState(() {
      _currentView = view;
      _token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case AuthView.landing:
        return AuthLandingScreen(
          errorMessage: widget.sessionController.errorMessage,
          onLogin: () => _open(AuthView.login),
        );
      case AuthView.login:
        return LoginScreen(
          controller: widget.sessionController,
          onBack: () => _open(AuthView.landing),
          onSignup: () => _open(AuthView.signup),
          onForgotPassword: () => _open(AuthView.forgotPassword),
        );
      case AuthView.signup:
        return SignupScreen(
          apiClient: widget.apiClient,
          onBack: () => _open(AuthView.landing),
          onLogin: () => _open(AuthView.login),
        );
      case AuthView.forgotPassword:
        return ForgotPasswordScreen(
          apiClient: widget.apiClient,
          onBack: () => _open(AuthView.login),
        );
      case AuthView.resetPassword:
        return ResetPasswordScreen(
          apiClient: widget.apiClient,
          token: _token,
          onBack: () => _open(AuthView.login),
        );
      case AuthView.verifyEmail:
        return VerifyEmailScreen(
          apiClient: widget.apiClient,
          token: _token,
          onBackToLogin: () => _open(AuthView.login),
          onBackToLanding: () => _open(AuthView.landing),
        );
    }
  }
}

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({
    super.key,
    required this.errorMessage,
    required this.onLogin,
  });

  final String? errorMessage;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/side_login.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empieza con Pickados',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Sigue picks, analiza jugadas y conecta con la comunidad tipster desde un solo lugar.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (errorMessage != null) ...[
                          _MessageCard(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            borderColor: Colors.white.withValues(alpha: 0.22),
                            textColor: Colors.white,
                            message: errorMessage!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF2AF2B),
                              foregroundColor: const Color(0xFF151515),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Comenzar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.apiClient,
    required this.onBack,
    required this.onLogin,
  });

  final ApiClient apiClient;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _bioController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 21, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );

    if (date == null || !mounted) {
      return;
    }

    _birthDateController.text =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final availability = await widget.apiClient.checkAvailability(
        username: _usernameController.text.trim().toLowerCase(),
        email: _emailController.text.trim().toLowerCase(),
      );

      if (!availability.usernameAvailable) {
        setState(() {
          _errorMessage = 'Este username ya esta registrado.';
        });
        return;
      }

      if (!availability.emailAvailable) {
        setState(() {
          _errorMessage = 'Este correo ya esta registrado.';
        });
        return;
      }

      await widget.apiClient.registerTipster(
        name: _nameController.text,
        lastname: _lastnameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        birthDate: _birthDateController.text,
        bio: _bioController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Revisa tu correo para verificarla.'),
        ),
      );
      widget.onLogin();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No se pudo completar el registro.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Registro tipster',
      subtitle:
          'Completa tu perfil inicial para empezar a publicar picks desde la app.',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_errorMessage != null) ...[
              _MessageCard(
                backgroundColor: const Color(0xFFFFF1F0),
                borderColor: const Color(0xFFF2B8B5),
                textColor: const Color(0xFF8C2F27),
                message: _errorMessage!,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Escribe un nombre valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastnameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Apellido'),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Escribe un apellido valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 5) {
                  return 'Usa al menos 5 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electronico',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (!_isValidEmail(trimmed)) {
                  return 'Escribe un correo valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento',
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Selecciona tu fecha de nacimiento.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Bio'),
              validator: (value) {
                if ((value?.trim().length ?? 0) < 10) {
                  return 'Comparte una bio breve de al menos 10 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Contrasena'),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirmar contrasena',
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contrasenas no coinciden.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear cuenta tipster'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onLogin,
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.apiClient,
    required this.onBack,
  });

  final ApiClient apiClient;
  final VoidCallback onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await widget.apiClient.requestPasswordReset(email: _emailController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _message =
            'Te enviamos un enlace temporal para actualizar tu contrasena.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No fue posible procesar la solicitud.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Recuperar contrasena',
      subtitle:
          'Ingresa tu correo y te enviaremos un enlace para restablecerla.',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_message != null) ...[
              _MessageCard(
                backgroundColor: const Color(0xFFEAF7EE),
                borderColor: const Color(0xFFB7E1C1),
                textColor: const Color(0xFF245D35),
                message: _message!,
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null) ...[
              _MessageCard(
                backgroundColor: const Color(0xFFFFF1F0),
                borderColor: const Color(0xFFF2B8B5),
                textColor: const Color(0xFF8C2F27),
                message: _errorMessage!,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electronico',
              ),
              validator: (value) {
                if (!_isValidEmail(value?.trim() ?? '')) {
                  return 'Escribe un correo valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onBack,
  });

  final ApiClient apiClient;
  final String? token;
  final VoidCallback onBack;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = widget.token?.trim() ?? '';
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'El enlace no contiene un token valido.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await widget.apiClient.resetPassword(
        token: token,
        newPassword: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Contrasena actualizada correctamente.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No fue posible actualizar la contrasena.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = widget.token?.trim().isNotEmpty ?? false;

    return AuthScaffold(
      title: 'Actualizar contrasena',
      subtitle: hasToken
          ? 'Crea una nueva contrasena para tu cuenta.'
          : 'Abre este flujo desde el enlace recibido por correo.',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_message != null) ...[
              _MessageCard(
                backgroundColor: const Color(0xFFEAF7EE),
                borderColor: const Color(0xFFB7E1C1),
                textColor: const Color(0xFF245D35),
                message: _message!,
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null || !hasToken) ...[
              _MessageCard(
                backgroundColor: const Color(0xFFFFF1F0),
                borderColor: const Color(0xFFF2B8B5),
                textColor: const Color(0xFF8C2F27),
                message: _errorMessage ?? 'El enlace no es valido o ya expiro.',
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contrasena'),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contrasena',
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contrasenas no coinciden.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting || !hasToken ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Actualizar contrasena'),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onBackToLogin,
    required this.onBackToLanding,
  });

  final ApiClient apiClient;
  final String? token;
  final VoidCallback onBackToLogin;
  final VoidCallback onBackToLanding;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = true;
  bool _success = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final token = widget.token?.trim() ?? '';
    if (token.isEmpty) {
      setState(() {
        _loading = false;
        _success = false;
        _message = 'No se encontro el token de verificacion.';
      });
      return;
    }

    try {
      await widget.apiClient.verifyEmail(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _success = true;
        _message = 'Tu correo electronico ha sido verificado con exito.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _success = false;
        _message = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _success = false;
        _message =
            'Hubo un error al verificar tu correo. El enlace puede haber expirado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verificacion de correo',
      subtitle: 'Validamos tu cuenta para que puedas entrar al feed.',
      onBack: _success ? widget.onBackToLogin : widget.onBackToLanding,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Icon(
                  _success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 72,
                  color: _success
                      ? const Color(0xFF1D9A6C)
                      : const Color(0xFFB94035),
                ),
                const SizedBox(height: 16),
                Text(
                  _success ? 'Correo verificado' : 'Error de verificacion',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _success
                      ? widget.onBackToLogin
                      : widget.onBackToLanding,
                  child: Text(
                    _success ? 'Ir a iniciar sesion' : 'Volver al inicio',
                  ),
                ),
              ],
            ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF4F9), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Volver'),
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 10),
                        Text(subtitle, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 24),
                        child,
                        const SizedBox(height: 24),
                        Text(
                          'Web: ${AppConfig.webBaseUrl}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.message,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AuthIntent {
  const _AuthIntent({required this.view, this.token});

  final AuthView view;
  final String? token;
}

_AuthIntent? _parseAuthIntent(Uri uri) {
  final segments = _normalizedSegments(uri);
  if (segments.isEmpty) {
    return null;
  }

  if (segments.length >= 2 &&
      segments[0] == 'auth' &&
      segments[1] == 'verify-email') {
    return _AuthIntent(
      view: AuthView.verifyEmail,
      token: uri.queryParameters['token'],
    );
  }

  if (segments.contains('reset-password')) {
    return _AuthIntent(
      view: AuthView.resetPassword,
      token: uri.queryParameters['token'],
    );
  }

  return null;
}

List<String> _normalizedSegments(Uri uri) {
  final pathSegments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (uri.scheme == 'pickados' && uri.host.isNotEmpty) {
    return [uri.host, ...pathSegments];
  }
  return pathSegments;
}

bool _isValidEmail(String value) {
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  return emailRegex.hasMatch(value);
}

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) {
    return 'Usa al menos 8 caracteres.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Incluye al menos una mayuscula.';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Incluye al menos una minuscula.';
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Incluye al menos un numero.';
  }
  return null;
}
