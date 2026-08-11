import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/entities/notificacion_entity.dart';
import '../../../../core/network/notification_polling_service.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRepository _repository = NotificationRepository();
  final NotificationPollingService _pollingService = NotificationPollingService();
  List<Notificacion> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscription = _pollingService.countStream.listen((count) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final list = await _repository.getAll();
    final unread = await _repository.getUnreadCount();

    if (mounted) {
      setState(() {
        _notifications = list;
        _unreadCount = unread;
        _isLoading = false;
      });
    }
  }

  void _markAsRead(int id) async {
    final error = await _repository.markAsRead(id);
    if (mounted && error != null) {
      showError(context, AppError(mensajeUsuario: error, esRecuperable: false));
    }
    _loadNotifications();
    _pollingService.refresh();
  }

  void _confirmNotification(int id, String newMensaje) async {
    final error = await _repository.updateMensaje(id, newMensaje);
    if (mounted && error != null) {
      showError(context, AppError(mensajeUsuario: error, esRecuperable: false));
    }
    _loadNotifications();
    _pollingService.refresh();
  }

  void _markAllAsRead() async {
    final error = await _repository.markAllAsRead();
    _loadNotifications();
    _pollingService.refresh();
    if (mounted) {
      if (error != null) {
        showError(context, AppError(mensajeUsuario: error, esRecuperable: false));
      } else {
        showSuccess(context, 'Todas las notificaciones marcadas como leídas');
      }
    }
  }

  void _resetSeeders() async {
    final error = await _repository.reseed();
    await _loadNotifications();
    _pollingService.refresh();
    if (mounted) {
      if (error != null) {
        showError(context, AppError(mensajeUsuario: error, esRecuperable: false));
      } else {
        showSuccess(context, 'Notificaciones restablecidas con datos de prueba');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _notifications.where((n) {
      final parts = n.mensaje.split('|');
      final status = parts.length > 3 ? parts[3] : '';
      return !n.leida || status != 'Confirmado';
    }).toList();

    final history = _notifications.where((n) {
      final parts = n.mensaje.split('|');
      final status = parts.length > 3 ? parts[3] : '';
      return n.leida && status == 'Confirmado';
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: RutxAppBar(
          title: 'Notificaciones',
          showBackButton: true,
          showBell: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.restore, color: AppTheme.textWhite),
              tooltip: 'Restablecer datos de prueba',
              onPressed: _resetSeeders,
            ),
            if (_unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all, color: AppTheme.textWhite),
                tooltip: 'Marcar todas como leídas',
                onPressed: _markAllAsRead,
              ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.textWhite,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppTheme.accentColor,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pending_actions),
                    SizedBox(width: 8),
                    Text(
                      'Pendientes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text(
                      'Historial',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
            : Column(
                children: [
                  if (_unreadCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tienes $_unreadCount mensajes sin leer',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildNotificationsList(pending, isPendingTab: true),
                        _buildNotificationsList(history, isPendingTab: false),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationsList(List<Notificacion> list, {required bool isPendingTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.assignment_turned_in_outlined : Icons.history_toggle_off,
              size: 64,
              color: AppTheme.textSecondary50,
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab
                  ? 'No tienes notificaciones pendientes.'
                  : 'Historial de notificaciones vacío.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      addRepaintBoundaries: true,
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(list[index]);
      },
    );
  }

  Widget _buildNotificationCard(Notificacion n) {
    final parts = n.mensaje.split('|');
    final title = parts[0];
    final sender = parts.length > 1 ? parts[1] : 'Oficina';
    final time = parts.length > 2 ? parts[2] : '00:00';
    final status = parts.length > 3 ? parts[3] : '';

    final isUnread = !n.leida;
    final isConfirmed = status == 'Confirmado';
    final avatarLetter = sender.isNotEmpty ? sender[0].toUpperCase() : 'O';

    return Card(
      color: Colors.white,
      surfaceTintColor: AppTheme.surfaceCard,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? AppTheme.accent30 : AppTheme.lightGrey,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isUnread
                  ? AppTheme.accentColor
                  : (isConfirmed ? AppTheme.statusGreen : AppTheme.borderLight),
              width: 5,
            ),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isUnread && n.id != null) {
              _markAsRead(n.id!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? AppTheme.primaryColor
                        : AppTheme.borderLight50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                        color: isUnread ? AppTheme.textWhite : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sender,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isUnread ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isConfirmed)
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.statusGreen, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Confirmado',
                                  style: TextStyle(
                                    color: AppTheme.statusGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          else
                            TextButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Confirmar Recibido'),
                              style: TextButton.styleFrom(
                                backgroundColor: AppTheme.accent10,
                                foregroundColor: AppTheme.accentColor,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                final newMsg = '$title|$sender|$time|Confirmado';
                                if (n.id != null) {
                                  _confirmNotification(n.id!, newMsg);
                                }
                              },
                            ),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NUEVO',
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
