import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/app_notification_card.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../data/auth_repository.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../sync/presentation/pages/download_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _rutxConfigUrl =
      'https://estr05.github.io/rutx/config.json';

  final _authRepository = AuthRepository();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _suspended = false;

  Future<bool> _isRutxEnabled() async {
    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      ).get<Map<String, dynamic>>(_rutxConfigUrl);

      if (response.statusCode == 200 && response.data != null) {
        return response.data!['rutx_enabled'] != false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    final enabled = await _isRutxEnabled();

    if (!mounted) return;

    if (!enabled) {
      setState(() {
        _isLoading = false;
        _suspended = true;
      });
      return;
    }

    final error = await _authRepository.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (error == null) {
        final db = AppDatabase();
        await db.initialize();
        final clientes = await db.clienteDao.getAll();
        final productos = await db.productDao.getAll();
        final hasData = clientes.isNotEmpty && productos.isNotEmpty;
        if (!mounted) return;

        if (hasData) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DownloadPage()),
          );
        }
      } else {
        showError(
          context,
          error,
          onRetry: error.esRecuperable ? _handleLogin : null,
        );
      }
    }
  }

  Widget _buildSuspended() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'RX',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'RUTX',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PLATAFORMA SUSPENDIDA',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              const AppNotificationCard(
                title: 'Plataforma suspendida',
                message:
                    'La plataforma se encuentra suspendida. Contacta a administración para más información.',
                icon: Icons.warning_amber_rounded,
                iconColor: AppTheme.statusOrange,
                backgroundColor: AppTheme.alertWarningBg,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text(
                  'SALIR',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_suspended) {
      return _buildSuspended();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Encabezado Azul Oscuro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 80,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            color: AppTheme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'RX',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'RUTX',
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accede con tu cuenta para comenzar tu jornada.',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usuario',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Tu nombre de usuario',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.textWhite,
                              ),
                            )
                            : const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        text: '¿Problemas para entrar? ',
                        style: TextStyle(color: AppTheme.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Contactar soporte',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
