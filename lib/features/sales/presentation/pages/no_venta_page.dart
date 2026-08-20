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
  String _folio = '';

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
    _generateFolio();
    _loadCausas();
  }

  void _generateFolio() {
    // Generate a local folio format like PNB + Random 6 digits or timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _folio = 'PNB${timestamp.substring(timestamp.length - 6)}';
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
        imageQuality: 70, // Compress slightly
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

  void _simulatePhoto() {
    // Dummy simulation for development
    setState(() {
      _imagePath = 'simulated_photo_path_123.jpg';
    });
    showSuccess(context, 'Foto simulada agregada exitosamente');
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

    setState(() => _isSaving = true);

    final now = _fechaHora.toIso8601String();

    final localStorage = LocalStorage();
    final vendedorId = await localStorage.getVendedorId() ?? 1;
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
      folio: _folio,
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
      if (syncResult?['success'] == true) {
        showSuccess(context, 'No Venta registrada y sincronizada con éxito');
      } else {
        showInfo(context, 'No Venta guardada localmente');
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(
        title: 'No Venta',
        showBackButton: true,
      ),
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

                    // Foto Section
                    Row(
                      children: [
                        Expanded(
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
                            label: const Text('FOTO (Obligatorio)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón algorítmico de prueba solicitado por el usuario
                        OutlinedButton(
                          onPressed: _simulatePhoto,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusOrange,
                            side: const BorderSide(
                              color: AppTheme.statusOrange,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Simular Prueba'),
                        ),
                      ],
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
                              : _imagePath == 'simulated_photo_path_123.jpg'
                              ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: AppTheme.statusGreen,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Foto Simulada (Modo Pruebas)',
                                    style: TextStyle(
                                      color: AppTheme.statusGreen,
                                      fontWeight: FontWeight.bold,
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
                        child: _isSaving
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
