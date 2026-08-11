import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../data/auth_repository.dart';
import 'login_page.dart';
import '../../../sync/presentation/pages/download_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../../widgets/premium_delivery_animation.dart';
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _checkAuthSession();
  }

  Future<void> _checkAuthSession() async {
    // Se añade un retraso para apreciar la animación premium completa
    await Future.delayed(const Duration(milliseconds: 4000));

    try {
      final hasToken = await _authRepository.hasValidToken();
      
      if (!mounted) return;

      if (hasToken) {
        final db = AppDatabase();
        
        // Timeout de 10 segundos para la inicialización de la BD
        await db.initialize().timeout(const Duration(seconds: 10));
        
        final clientes = await db.clienteDao.getAll().timeout(const Duration(seconds: 5));
        final productos = await db.productDao.getAll().timeout(const Duration(seconds: 5));
        
        if (!mounted) return;

        if (clientes.isNotEmpty && productos.isNotEmpty) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (_) {
      // Si algo falla (BD corrupta, timeout, etc.), redirigir al login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Azul oscuro
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo RX naranja
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor, // Naranja
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        'RX',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 42,
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
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'VENTAS EN RUTA',
                    style: TextStyle(
                      color: AppTheme.secondaryColor, // Azul claro
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32), // Ajustamos el espaciado para que respire la animación
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: const PremiumDeliveryAnimation(), // La nueva animación
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Iniciando...',
                    style: TextStyle(color: AppTheme.secondaryColor),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'v2.4.1 • Sincronizador M3',
                  style: TextStyle(color: AppTheme.secondaryColor60, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
