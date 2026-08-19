import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

class EndOfDayAnimation extends StatefulWidget {
  const EndOfDayAnimation({super.key});

  @override
  State<EndOfDayAnimation> createState() => _EndOfDayAnimationState();
}

class _EndOfDayAnimationState extends State<EndOfDayAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _carTranslation;
  late Animation<double> _carBounce;
  late Animation<double> _windTranslation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2800,
      ), // Un poco más rápido para el cierre
    );

    // Movimiento horizontal del auto (de la derecha 1.0 a la izquierda 0.0)
    _carTranslation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // Efecto de rebote del auto al avanzar
    _carBounce = TweenSequence<double>([
      for (int i = 0; i < 7; i++) ...[
        TweenSequenceItem(
          tween: Tween(
            begin: 0.0,
            end: -3.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: -3.0,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ],
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.85)),
    );

    // Viento/Líneas de velocidad (van hacia la derecha porque el camión va a la izquierda)
    _windTranslation = Tween<double>(begin: 0.0, end: 40.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.80, curve: Curves.linear),
      ),
    );

    // Esperar a que Flutter renderice y arrancar
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxDistance = constraints.maxWidth - 48;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final bool isCarMoving =
                  _controller.value > 0.15 && _controller.value < 0.85;

              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // 1. Carretera base (Línea)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 2. Líneas de velocidad (Viento)
                  if (isCarMoving)
                    Positioned(
                      bottom: 24,
                      // El viento sale por detrás del camión (a su derecha)
                      left: (_carTranslation.value * maxDistance) + 40,
                      child: Transform.translate(
                        offset: Offset(_windTranslation.value, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 15,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.textWhite.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.textWhite.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Tienda estática (Ya cerramos la jornada)
                  Positioned(
                    bottom: 8,
                    left: maxDistance,
                    child: Opacity(
                      opacity:
                          0.6, // Le bajamos la opacidad para dar a entender que ya está inactiva/cerrada
                      child: SvgPicture.asset(
                        'assets/images/store_3d.svg',
                        width: 48,
                        height: 48,
                        placeholderBuilder:
                            (BuildContext context) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // 4. Auto con efecto de rebote de regreso
                  Positioned(
                    bottom: 12,
                    left: 0,
                    child: Transform.translate(
                      offset: Offset(
                        _carTranslation.value * maxDistance,
                        _carBounce.value,
                      ),
                      child: SvgPicture.asset(
                        'assets/images/truck_comeback_3d.svg', // El nuevo camión mirando a la izquierda
                        width: 42,
                        height: 42,
                        placeholderBuilder:
                            (BuildContext context) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
