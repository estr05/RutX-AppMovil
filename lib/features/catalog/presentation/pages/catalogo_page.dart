import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/producto_entity.dart';
import '../../../../shared/widgets/rutx_app_bar.dart';
import '../../../../shared/widgets/sale_utils.dart';
import '../../../../shared/widgets/stock_label.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  // ==========================================
  // VARIABLES DE ESTADO (Intactas)
  // ==========================================
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;

  final ScrollController _scrollController = ScrollController();
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  final Map<String, int> _letterIndices = {};
  String _currentLetter = '';
  bool _isDragging = false;

  List<Producto> _productos = [];
  bool _isLoading = true;

  // Nuevo: Timer para evitar exceso de consultas al escribir rápido
  Timer? _debounce;

  // ==========================================
  // CICLO DE VIDA Y LÓGICA DE DATOS
  // ==========================================
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      await db
          .initialize(); // Nota: Idealmente, maneja esto como Singleton fuera de la vista

      List<Producto> list =
          _searchQuery.isEmpty
              ? (_minPrice != null || _maxPrice != null
                  ? await db.productDao.getAll()
                  : await db.productDao.getFirst(50))
              : await db.productDao.search(_searchQuery);

      if (_minPrice != null || _maxPrice != null) {
        list =
            list.where((p) {
              final price = precioConImpuestoProducto(p);
              if (_minPrice != null && price < _minPrice!) return false;
              if (_maxPrice != null && price > _maxPrice!) return false;
              return true;
            }).toList();
      }

      list.sort((a, b) => a.nombre.compareTo(b.nombre));

      if (mounted) {
        setState(() {
          _productos = list;
          _calculateLetterIndices();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar catálogo: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String val) {
    // Actualiza la UI al instante (para mostrar la 'X')
    setState(() {
      _searchQuery = val;
    });

    // Retrasa la consulta a BD por 300ms
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadData();
    });
  }

  // ==========================================
  // LÓGICA DEL SLIDER ALFABÉTICO
  // ==========================================
  void _calculateLetterIndices() {
    _letterIndices.clear();
    for (int i = 0; i < _productos.length; i++) {
      String firstLetter =
          _productos[i].nombre.isNotEmpty
              ? _productos[i].nombre[0].toUpperCase()
              : '';
      if (firstLetter.isNotEmpty && !_letterIndices.containsKey(firstLetter)) {
        _letterIndices[firstLetter] = i;
      }
    }
  }

  void _scrollToLetter(String letter) {
    if (_letterIndices.containsKey(letter)) {
      int index = _letterIndices[letter]!;
      double offset = index * 94.0;

      if (offset > _scrollController.position.maxScrollExtent) {
        offset = _scrollController.position.maxScrollExtent;
      }
      _scrollController.jumpTo(offset);
    }
  }

  void _handleSliderDrag(double dy, double maxHeight) {
    if (maxHeight <= 0) return;
    int index = ((dy / maxHeight) * _alphabet.length).floor();
    index = index.clamp(0, _alphabet.length - 1);
    String letter = _alphabet[index];

    if (_currentLetter != letter || !_isDragging) {
      setState(() {
        _currentLetter = letter;
        _isDragging = true;
      });
      _scrollToLetter(letter);
    }
  }

  // ==========================================
  // HELPERS DE DISEÑO (Colores e Iconos)
  // ==========================================
  Color _getAvatarColor(String clave) {
    final prefix =
        clave.length >= 3 ? clave.substring(0, 3).toUpperCase() : 'PROD';
    switch (prefix) {
      case 'REF':
        return const Color(0xFFC62828);
      case 'AGU':
        return const Color(0xFF0288D1);
      case 'JUG':
        return const Color(0xFFF57C00);
      case 'GAL':
        return const Color(0xFF8D6E63);
      case 'CHI':
        return const Color(0xFF00897B);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getProductIcon(String clave) {
    final prefix =
        clave.length >= 3 ? clave.substring(0, 3).toUpperCase() : 'PROD';
    switch (prefix) {
      case 'REF':
        return Icons.local_drink_outlined;
      case 'AGU':
        return Icons.water_drop_outlined;
      case 'JUG':
        return Icons.breakfast_dining_outlined;
      case 'GAL':
        return Icons.cookie_outlined;
      case 'CHI':
        return Icons.circle_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  // ==========================================
  // CONSTRUCCIÓN DE LA INTERFAZ (UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const RutxAppBar(
        title: 'Catálogo de Productos',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildSearchBarAndStats(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndStats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.lightGrey.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o código...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          // Limpia el input y recarga
                          FocusScope.of(context).unfocus();
                          _onSearchChanged('');
                        },
                      )
                      : null,
              filled: true,
              fillColor: AppTheme.bgWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Más profesional que redondo extremo
                borderSide: BorderSide(
                  color: AppTheme.lightGrey.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightGrey.withValues(alpha: 0.5),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Artículos',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_productos.length}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showFilterModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: AppTheme.textPrimary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      );
    }

    if (_productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron productos.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            left: 16,
            right: 40,
            bottom: 24,
            top: 12,
          ),
          itemCount: _productos.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) => _buildProductCard(_productos[index]),
        ),

        if (MediaQuery.of(context).viewInsets.bottom == 0)
          _buildAlphabetSidebar(),

        if (_isDragging && _currentLetter.isNotEmpty)
          _buildLetterIndicatorOverlay(),
      ],
    );
  }

  Widget _buildProductCard(Producto p) {
    final avatarColor = _getAvatarColor(p.clave);
    final icon = _getProductIcon(p.clave);
    final price = precioConImpuestoProducto(p);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.textWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: avatarColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.lightGrey),
                        ),
                        child: Text(
                          p.clave,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${p.articuloId}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  StockLabel(existencias: p.existencias),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.statusGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'P.U.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabetSidebar() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onVerticalDragDown:
                (d) => _handleSliderDrag(
                  d.localPosition.dy,
                  constraints.maxHeight,
                ),
            onVerticalDragUpdate:
                (d) => _handleSliderDrag(
                  d.localPosition.dy,
                  constraints.maxHeight,
                ),
            onVerticalDragEnd: (_) => setState(() => _isDragging = false),
            onVerticalDragCancel: () => setState(() => _isDragging = false),
            child: Container(
              width: 32,
              height: constraints.maxHeight,
              color: Colors.transparent,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      _alphabet.map((letter) {
                        bool isSelected = _isDragging && _currentLetter == letter;
                        return Text(
                          letter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLetterIndicatorOverlay() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          _currentLetter,
          style: const TextStyle(
            fontSize: 36,
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL DE FILTROS
  // ==========================================
  void _showFilterModal() {
    TextEditingController minPriceCtrl = TextEditingController(
      text: _minPrice?.toString() ?? '',
    );
    TextEditingController maxPriceCtrl = TextEditingController(
      text: _maxPrice?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        void onClear() {
          minPriceCtrl.clear();
          maxPriceCtrl.clear();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Precio Mínimo',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Precio Máximo',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: minPriceCtrl,
                  builder: (context, minVal, _) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: maxPriceCtrl,
                      builder: (context, maxVal, _) {
                        final hasFilters =
                            minVal.text.isNotEmpty || maxVal.text.isNotEmpty;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: hasFilters ? onClear : null,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Restablecer precios'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  hasFilters
                                      ? AppTheme.accentColor
                                      : AppTheme.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _minPrice = double.tryParse(minPriceCtrl.text);
                            _maxPrice = double.tryParse(maxPriceCtrl.text);
                          });
                          Navigator.pop(ctx);
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
