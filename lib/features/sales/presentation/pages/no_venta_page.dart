import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/entities/cliente_entity.dart';
import '../../../../core/database/entities/causa_no_venta_entity.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../../shared/widgets/feedback_utils.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../data/sales_repository.dart';
import '../../../../core/storage/local_storage.dart';

class NoVentaPage extends StatefulWidget {
  final Cliente cliente;

  const NoVentaPage({super.key, required this.cliente});

  @override
  State<NoVentaPage> createState() => _NoVentaPageState();
}

class _NoVentaPageState extends State<NoVentaPage> {
  final TextEditingController _comentarioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<CausaNoVenta> _causas = [];
  CausaNoVenta? _selectedCausa;
  String? _imagePath;

  /// Fecha y hora en que se registra la no venta (se muestra al usuario
  /// y es la que se guarda, para que coincida con el resumen).
  final DateTime _fechaHora = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;

  String get _fechaHoraDisplay =>
      DateFormat('dd/MM/yyyy HH:mm').format(_fechaHora);

  @override
  void initState() {
    super.initState();
    _loadCausas();
  }

  Future<void> _loadCausas() async {
    final db = AppDatabase();
    await db.initialize();
    var causas = await db.causaNoVentaDao.getAll();

    if (causas.isEmpty) {
      await db.causaNoVentaDao.insertAll(CausaNoVenta.causasSemilla);
      causas = await db.causaNoVentaDao.getAll();
    }
    setState(() {
      _causas = causas;
      if (_causas.isNotEmpty) {
        _selectedCausa = _causas.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality:
            70, // Reducir dimensiones y compresión para ~150KB por foto
      );
      if (photo != null) {
        // image_picker guarda en la caché del sistema (se puede borrar en
        // cualquier momento). Se copia a documentos para que la foto
        // sobreviva offline, a la limpieza de caché y a los reintentos de
        // sincronización.
        final persistente = await _guardarFotoPersistente(photo);
        if (!mounted) return;
        setState(() {
          _imagePath = persistente;
        });
      }
    } catch (e) {
      showErrorMessage(context, 'Error al tomar foto: $e');
    }
  }

  /// Copia la foto a un directorio persistente de la app (documentos).
  Future<String> _guardarFotoPersistente(XFile photo) async {
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/fotos_no_venta');
    if (!carpeta.existsSync()) {
      carpeta.createSync(recursive: true);
    }
    final nombre = 'no_venta_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destino = '${carpeta.path}/$nombre';
    await File(photo.path).copy(destino);
    return destino;
  }

  Future<void> _saveNoVenta() async {
    if (_isSaving) return;
    if (_selectedCausa == null) {
      showErrorMessage(context, 'Debes seleccionar una causa');
      return;
    }

    if (_imagePath == null) {
      showErrorMessage(context, 'Es obligatorio adjuntar una fotografía');
      return;
    }

    if (!File(_imagePath!).existsSync()) {
      showErrorMessage(
        context,
        'La foto ya no está disponible. Vuelve a tomarla.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = _fechaHora.toIso8601String();

    final localStorage = LocalStorage();
    final vendedorId = await localStorage.getVendedorId();
    if (vendedorId == null) {
      if (mounted) {
        showErrorMessage(
          context,
          'Sesión inválida. Por favor reinicia la app.',
        );
        setState(() => _isSaving = false);
      }
      return;
    }
    final cajeroId = await localStorage.getCajeroId();
    final cajaId = await localStorage.getCajaId();
    final almacenId = await localStorage.getAlmacenId();
    final sucursalId = await localStorage.getSucursalId();
    final usuario = await localStorage.getUsuario();

    final noVenta = VentaPendiente(
      ventaMovilId: const Uuid().v4(),
      vendedorId: vendedorId,
      clienteId: widget.cliente.clienteId,
      clienteNombre: widget.cliente.nombreCliente,
      fechaHora: now,
      estado: 'no_venta',
      total: 0.0,
      folio: '',
      cajaId: cajaId,
      cajeroId: cajeroId,
      almacenId: almacenId,
      sucursalId: sucursalId,
      usuarioCreador: usuario,
      detalles: [
        {
          'causa_id': _selectedCausa!.causaId,
          'causa_desc': _selectedCausa!.descripcion,
          'comentario': _comentarioController.text,
          'foto_path': _imagePath,
        },
      ],
    );

    final salesRepository = SalesRepository();
    final syncResult = await salesRepository.saveAndSyncSale(noVenta);

    if (mounted) {
      if (syncResult == null || syncResult['error'] == 'save_failed') {
        showErrorMessage(
          context,
          'No se pudo guardar la visita. Intenta de nuevo.',
        );
        setState(() => _isSaving = false);
        return;
      }
      if (syncResult['success'] == true) {
        showSuccess(
          context,
          'Visita y evidencia registradas y sincronizadas con éxito',
        );
      } else {
        showSuccess(
          context,
          'Visita guardada localmente. Se enviará al conectarse.',
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(title: 'No Venta', showBackButton: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Resumen Cliente / Folio
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'Fecha y hora',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _fechaHoraDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            height: 24,
                            color: AppTheme.borderLight,
                          ),
                          Row(
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'Cliente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${widget.cliente.clave.isNotEmpty ? widget.cliente.clave : widget.cliente.clienteId} - ${widget.cliente.nombreCliente}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Causa Dropdown
                    const Text(
                      'Causa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CausaNoVenta>(
                          isExpanded: true,
                          value: _selectedCausa,
                          items:
                              _causas.map((CausaNoVenta causa) {
                                return DropdownMenuItem<CausaNoVenta>(
                                  value: causa,
                                  child: Text(
                                    causa.descripcion,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (CausaNoVenta? newValue) {
                            setState(() {
                              _selectedCausa = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comentario
                    const Text(
                      'Comentario',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _comentarioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Agregar notas...',
                        filled: true,
                        fillColor: AppTheme.bgWhite,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.borderLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Foto Section (Obligatoria para validación presencial)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('TOMAR FOTO (Obligatorio)'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Preview Area
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderLight,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child:
                          _imagePath == null
                              ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: AppTheme.textSecondary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No se ha tomado foto',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                    ),
                    const SizedBox(height: 32),

                    // Botón Guardar Inferior
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveNoVenta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: AppTheme.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textWhite,
                                  ),
                                )
                                : const Text(
                                  'GUARDAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }
}
