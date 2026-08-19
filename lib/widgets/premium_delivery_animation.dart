import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

class PremiumDeliveryAnimation extends StatefulWidget {
  const PremiumDeliveryAnimation({super.key});

  @override
  State<PremiumDeliveryAnimation> createState() =>
      _PremiumDeliveryAnimationState();
}

class _PremiumDeliveryAnimationState extends State<PremiumDeliveryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _carTranslation;
  late Animation<double> _carBounce;
  late Animation<double> _storeScale;
  late Animation<double> _coinY;
  late Animation<double> _coinOpacity;
  late Animation<double> _coinRotation;
  late Animation<double> _windTranslation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Movimiento horizontal del auto
    _carTranslation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.60, curve: Curves.easeInOutCubic),
      ),
    );

    // Efecto de rebote del auto al avanzar
    _carBounce = TweenSequence<double>([
      for (int i = 0; i < 5; i++) ...[
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
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.60)),
    );

    // Viento/Líneas de velocidad
    _windTranslation = Tween<double>(begin: 0.0, end: -30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.55, curve: Curves.linear),
      ),
    );

    // Escala elástica de la tienda cuando llega el auto
    _storeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.75)),
    );

    // Movimiento vertical de la moneda
    _coinY = Tween<double>(begin: 0.0, end: -45.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOutBack),
      ),
    );

    // Rotación 3D simulada de la moneda
    _coinRotation = Tween<double>(begin: 0.0, end: math.pi * 4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );

    // Opacidad de la moneda
    _coinOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.70, curve: Curves.easeIn),
      ),
    );

    // Esperar a que Flutter termine de renderizar el primer frame antes de arrancar la animación
    // Esto evita que la animación se salte el viaje del camión si el teléfono es lento al abrir la app.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        // En lugar de repeat(), usamos forward() para que se quede estacionado en la tienda
        // y no se reinicie a la posición original justo antes de entrar a la app.
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
              // Desvanece la moneda al final del ciclo
              final double finalCoinOpacity =
                  _controller.value > 0.85
                      ? 1.0 -
                          ((_controller.value - 0.85) / 0.15).clamp(0.0, 1.0)
                      : _coinOpacity.value;

              final bool isCarMoving =
                  _controller.value > 0.15 && _controller.value < 0.60;

              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // 1. Carretera base (Línea continua)
                  Positioned(
                    bottom: 20,
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

                  // 2. Líneas de velocidad (Viento) solo cuando el auto se mueve
                  if (isCarMoving)
                    Positioned(
                      bottom: 24,
                      left: (_carTranslation.value * maxDistance) - 20,
                      child: Transform.translate(
                        offset: Offset(_windTranslation.value, 0),
                        child: Opacity(
                          opacity: 0.6,
                          child: Container(
                            width: 15,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.textWhite.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Moneda flotante con Rotación
                  Positioned(
                    bottom: 30,
                    left: maxDistance + 12,
                    child: Transform.translate(
                      offset: Offset(0, _coinY.value),
                      child: Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Perspectiva sutil
                              ..rotateY(_coinRotation.value),
                        child: Opacity(
                          opacity: finalCoinOpacity.clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.statusGreenBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.attach_money_rounded,
                              color: AppTheme.statusGreen,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Tienda con efecto Elástico (Estilo DiDi Food)
                  Positioned(
                    bottom: 8,
                    left: maxDistance,
                    child: Transform.scale(
                      scale: _storeScale.value,
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset(
                        'assets/images/store_3d.svg', // Tu archivo SVG de Canva
                        width: 48,
                        height: 48,
                        // Fallback: Espacio vacío para evitar parpadeos de iconos viejos
                        placeholderBuilder:
                            (BuildContext context) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // 5. Auto con efecto de rebote (Estilo DiDi Drive)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    child: Transform.translate(
                      offset: Offset(
                        _carTranslation.value * maxDistance,
                        _carBounce.value,
                      ),
                      child: SvgPicture.asset(
                        'assets/images/truck_3d.svg', // Tu archivo SVG de Canva
                        width: 42,
                        height: 42,
                        // Fallback vacío para evitar parpadeo
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
