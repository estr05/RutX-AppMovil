import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/end_of_day_animation.dart';
import '../../../auth/presentation/pages/login_page.dart';

class EndOfDaySplashPage extends StatefulWidget {
  const EndOfDaySplashPage({super.key});

  @override
  State<EndOfDaySplashPage> createState() => _EndOfDaySplashPageState();
}

class _EndOfDaySplashPageState extends State<EndOfDaySplashPage> {
  @override
  void initState() {
    super.initState();
    // Esperar unos segundos para que se vea la animación del camión alejándose de la tienda
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder:
                (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Cambiado al azul primario
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EndOfDayAnimation(),
            const SizedBox(height: 48),
            const Text(
              'Jornada Cerrada',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.surfaceColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Buen trabajo! Nos vemos mañana.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.surfaceColor.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
