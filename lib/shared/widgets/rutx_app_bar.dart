import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../core/network/notification_polling_service.dart';
import 'connection_indicator.dart';

/// AppBar estándar de RutX.
///
/// Muestra: [RutX | Indicador Conexión + Notificaciones] y el nombre de la vista.
/// Usa un [AppBar] estándar con [toolbarHeight] fijo, por lo que la altura es
/// idéntica en todas las pantallas (y en [RutxSliverAppBar] del Inicio).
///
/// La campana de notificaciones carga su propio contador de no leídas, así el
/// badge aparece en TODAS las pantallas, no solo en el Inicio.
class RutxAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Altura del contenido (sin contar la barra de estatus del sistema,
  /// que la agrega el framework automáticamente).
  static const double kToolbarHeight = 114;

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  /// Acciones del usuario (botón guardar, refrescar, etc.). Se muestran junto
  /// a la campana en la fila superior.
  final List<Widget>? actions;

  /// Barra inferior opcional (ej: TabBar de Notificaciones).
  final PreferredSizeWidget? bottom;

  /// Si `false`, oculta la campana (ej: en la propia pantalla de notificaciones).
  final bool showBell;

  const RutxAppBar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.bottom,
    this.showBell = true,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  State<RutxAppBar> createState() => _RutxAppBarState();
}

class _RutxAppBarState extends State<RutxAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: RutxAppBar.kToolbarHeight,
      titleSpacing: 0,
      title: _RutxAppBarContent(
        title: widget.title,
        showBackButton: widget.showBackButton,
        onBack: widget.onBack,
        actions: widget.actions,
        showBell: widget.showBell,
      ),
      bottom: widget.bottom,
    );
  }
}

/// AppBar para CustomScrollView (SliverList / SliverGrid) del Inicio.
/// Calcula la misma altura que [RutxAppBar] para que Inicio y el resto de
/// pantallas queden exactamente iguales.
class RutxSliverAppBar extends StatelessWidget {
  final String title;
  final bool pinned;
  final bool floating;

  const RutxSliverAppBar({
    Key? key,
    required this.title,
    this.pinned = true,
    this.floating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      expandedHeight: RutxAppBar.kToolbarHeight,
      toolbarHeight: RutxAppBar.kToolbarHeight,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: SafeArea(
          bottom: false,
          child: _RutxAppBarContent(title: title),
        ),
      ),
    );
  }
}

/// Contenido compartido entre [RutxAppBar] (Scaffold) y [RutxSliverAppBar]
/// (Inicio). Sin SafeArea: cada contenedor se encarga de la barra de estatus.
class _RutxAppBarContent extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBell;

  const _RutxAppBarContent({
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.showBell = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: [Atras] RutX + Indicador de Conexión + Campana + Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBackButton) ...[
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 32,
                    height: 32,
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RutX',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ConnectionIndicator(),
                  const SizedBox(width: 4),
                  if (showBell) const _NotificationBell(),
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    ...actions!,
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fila 2: Nombre de la vista + línea azul
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: double.infinity,
            color: AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }
}

/// Campana de notificaciones con badge de no leídas.
///
/// Carga el conteo desde la BD local y se mantiene al día escuchando
/// [NotificationPollingService.countStream], por lo que el badge aparece en
/// todas las pantallas que usan [RutxAppBar] / [RutxSliverAppBar].
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with WidgetsBindingObserver {
  final NotificationRepository _repository = NotificationRepository();
  StreamSubscription<int>? _subscription;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = NotificationPollingService().countStream.listen((count) {
      if (mounted) setState(() => _unread = count);
    });
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final count = await _repository.getUnreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {
      // BD aún no inicializada: se ignora, el polling lo corregirá.
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none,
            color: AppTheme.textWhite,
            size: 26,
          ),
          onPressed: _openNotifications,
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppTheme.statusRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  _unread > 9 ? '9+' : _unread.toString(),
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
