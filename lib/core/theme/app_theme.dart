import 'package:flutter/material.dart';

// =============================================================================
// PALETA CROMATICA SEMANTICA - TEKNOLOGIX RUTX
// Agrupa todos los colores del proyecto en constantes con nombre semantico
// para evitar colores hardcodeados y garantizar uniformidad visual.
// =============================================================================

class AppTheme {
  // ───────────────────────────────────────────────────────────────────────────
  // BRAND (Colores corporativos)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color primaryColor    = Color(0xFF003B5C); // Dark Blue - Fondo AppBar, headers
  static const Color accentColor     = Color(0xFFFF6A13); // Orange - Botones primarios, totales, accentos
  static const Color secondaryColor  = Color(0xFFA8C8E9); // Light Blue - Fondos secundarios, seleccion

  // ── Alias backward-compatible (nombres originales) ──
  static const Color backgroundColor = bgLight;
  static const Color surfaceColor    = surfaceCard;
  static const Color lightGrey       = borderLight;

  // ───────────────────────────────────────────────────────────────────────────
  // SURFACE (Superficies y fondos)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color bgLight         = Color(0xFFF4F6F8); // Fondo general de pantallas
  static const Color bgWhite         = Colors.white;       // Fondo de tarjetas, inputs
  static const Color bgDark          = Color(0xFF003B5C); // Mismo que primary, fondos oscuros
  static const Color surfaceCard     = Colors.white;       // Tarjetas (SaleCard, SummaryMetrics, TicketCard)
  static const Color surfaceDark     = Color(0xFF003B5C); // Headers oscuros

  // ───────────────────────────────────────────────────────────────────────────
  // TEXT (Texto)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFF343D45); // Texto principal (titles, body)
  static const Color textSecondary   = Color(0xFFB0B0B0); // Texto secundario (subtitles, hints)
  static const Color textWhite       = Colors.white;       // Texto sobre fondos oscuros
  static const Color textAccent      = Color(0xFFFF6A13); // Texto con color accent (total, warnings)

  // ───────────────────────────────────────────────────────────────────────────
  // BORDERS & DIVIDERS (Bordes y separadores)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color borderLight     = Color(0xFFE0E0E0); // Bordes de tarjetas, separadores
  static const Color borderAccent    = Color(0xFFFFE0B2); // Borde accent suave (botones outline)
  static const Color divider         = Color(0xFFE0E0E0); // Separadores genericos

  // ───────────────────────────────────────────────────────────────────────────
  // STATUS - TEXT (Colores de estado - texto/icono)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color statusGreen     = Color(0xFF2E7D32); // Enviada / Exito
  static const Color statusOrange    = Color(0xFFE65100); // Pendiente / Advertencia
  static const Color statusRed       = Color(0xFFC62828); // Error / Rechazado
  static const Color statusAmber     = Color(0xFFF9A825); // Referencia local / Sin conexion
  static const Color statusGrey      = Color(0xFF9E9E9E); // Estado desconocido

  // ───────────────────────────────────────────────────────────────────────────
  // STATUS - BACKGROUND (Fondo de badges de estado)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color statusGreenBg   = Color(0x1F2E7D32); // statusGreen al 12%
  static const Color statusOrangeBg  = Color(0x1FE65100); // statusOrange al 12%
  static const Color statusRedBg     = Color(0x1FC62828); // statusRed al 12%
  static const Color statusGreyBg    = Color(0x1F9E9E9E); // statusGrey al 12%

  // ───────────────────────────────────────────────────────────────────────────
  // ALERTS & NOTIFICATIONS (Alertas y notificaciones)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color alertSuccessBg   = Color(0xFFE8F5E9); // Fondo exito (check verde claro)
  static const Color alertErrorBg     = Color(0xFFFFEBEE); // Fondo error (rojo claro)
  static const Color alertWarningBg   = Color(0xFFFFF8E1); // Fondo advertencia (amarillo claro)
  static const Color alertWarningText = Color(0xFF795500); // Texto de advertencia

  // ───────────────────────────────────────────────────────────────────────────
  // SURFACE ACCENT (Variantes de accentColor para fondos/bordes)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color accentBgLight   = Color(0xFFFFF3E0); // Fondo accent muy claro (botones outline)
  static const Color accentBorder    = Color(0xFFFFE0B2); // Borde accent suave (outline buttons)
  static const Color accent10        = Color(0x1AFF6A13); // accentColor al 10% (fondos hover)
  static const Color accent30        = Color(0x4DFF6A13); // accentColor al 30%
  static const Color accent50        = Color(0x80FF6A13); // accentColor al 50%

  // ───────────────────────────────────────────────────────────────────────────
  // SURFACE PRIMARY (Variantes de primaryColor para fondos/bordes)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color primary10       = Color(0x1A003B5C); // primaryColor al 10%
  static const Color primary20       = Color(0x33003B5C); // primaryColor al 20%
  static const Color primaryLightBg  = Color(0xFFE3F2FD); // Fondo azul claro (info cards)
  static const Color primaryDarkText = Color(0xFF005691); // Texto azul oscuro (charts)

  // ───────────────────────────────────────────────────────────────────────────
  // INFO (Tarjetas informativas)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color infoBlue        = Color(0xFF1565C0); // Icono info azul
  static const Color infoBlueBg      = Color(0xFFE3F2FD); // Fondo info azul
  static const Color infoCyan        = Color(0xFF0277BD); // Icono info cyan
  static const Color infoCyanBg      = Color(0xFFE1F5FE); // Fondo info cyan

  // ───────────────────────────────────────────────────────────────────────────
  // CHART (Dashboard y graficas)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color chartBlue       = Color(0xFF005691); // Texto/icono de graficas
  static const Color chartBlueBg     = Color(0xFFEBF5FE); // Fondo de graficas
  static const Color chartBlueBorder = Color(0xFFD2E8FC); // Borde de graficas

  // ───────────────────────────────────────────────────────────────────────────
  // CATEGORY (Categorias de productos - catalogo)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color categoryRed     = Color(0xFFC62828); // Red - Soft Drinks
  static const Color categoryBlue    = Color(0xFF0288D1); // Blue - Water
  static const Color categoryOrange  = Color(0xFFF57C00); // Orange - Juices
  static const Color categoryBrown   = Color(0xFF8D6E63); // Brown - Cookies
  static const Color categoryTeal    = Color(0xFF00897B); // Teal - Gums

  // ───────────────────────────────────────────────────────────────────────────
  // CLIENT (Avatares de clientes - colores variados)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color avatarBlue      = Color(0xFF1565C0);
  static const Color avatarOrange    = Color(0xFFFF6D00);
  static const Color avatarCyan      = Color(0xFF00B0FF);
  static const Color avatarPurple    = Color(0xFF7C4DFF);
  static const Color avatarGreen     = Color(0xFF00C853);
  static const Color avatarAmber     = Color(0xFFFFAB00);

  // ───────────────────────────────────────────────────────────────────────────
  // SURFACE GREY (Tonos de gris para fondos de widgets)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color surfaceGrey100  = Color(0xFFF5F5F5); // Gris muy claro (fondos de search, inputs)
  static const Color surfaceGrey     = Color(0xFF9E9E9E); // Gris medio (bordes, iconos secundarios)

  // ───────────────────────────────────────────────────────────────────────────
  // OPACIDADES PRECALCULADAS (Para evitar withOpacity() en cada frame)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color white20         = Color(0x33FFFFFF); // Colors.white al 20%
  static const Color white80         = Color(0xCCFFFFFF); // Colors.white al 80%
  static const Color black02         = Color(0x05000000); // Colors.black al 2%
  static const Color black05         = Color(0x0D000000); // Colors.black al 5%
  static const Color black08         = Color(0x14000000); // Colors.black al 8% (sombras ticket)
  static const Color textPrimary05   = Color(0x0D343D45); // textPrimary al 5%
  static const Color textSecondary50 = Color(0x80B0B0B0); // textSecondary al 50%
  static const Color borderLight50   = Color(0x80E0E0E0); // borderLight al 50%
  static const Color secondaryColor60 = Color(0x99A8C8E9); // secondaryColor al 60% (version info)

  // ───────────────────────────────────────────────────────────────────────────
  // SURFACE ACCENT LIGHTER (Variante aun mas clara de accentColor)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color accentBgLighter = Color(0xFFFFF9F2); // Fondo accent clarisimo (search field)

  // ───────────────────────────────────────────────────────────────────────────
  // THEME (Configuracion de Material Theme)
  // ───────────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textWhite,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

// =============================================================================
// STATUS COLOR UTILITY
// Centraliza el mapeo estado -> color para usar en SaleCard, VentaDetallePage,
// y cualquier widget que necesite colorear segun estado de venta.
// =============================================================================

/// Define los atributos visuales completos para un badge de estado.
class StatusBadgeStyle {
  final Color backgroundColor;
  final Color textColor;
  final String label;

  const StatusBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
  });
}

/// Mapea un estado de venta a sus colores y etiqueta correspondientes.
///
/// Uso:
///   final style = StatusColor.resolve(venta.estado);
///   Container(color: style.backgroundColor, child: Text(style.label))
class StatusColor {
  /// Resuelve el estilo visual completo para un estado de venta.
  static StatusBadgeStyle resolve(String estado) {
    switch (estado.toLowerCase()) {
      case 'enviada':
        return const StatusBadgeStyle(
          backgroundColor: AppTheme.statusGreenBg,
          textColor: AppTheme.statusGreen,
          label: 'Enviada',
        );
      case 'pendiente':
        return const StatusBadgeStyle(
          backgroundColor: AppTheme.statusOrangeBg,
          textColor: AppTheme.statusOrange,
          label: 'Pendiente',
        );
      case 'error':
        return const StatusBadgeStyle(
          backgroundColor: AppTheme.statusRedBg,
          textColor: AppTheme.statusRed,
          label: 'Error',
        );
      default:
        return StatusBadgeStyle(
          backgroundColor: AppTheme.statusGreyBg,
          textColor: AppTheme.statusGrey,
          label: estado,
        );
    }
  }

  /// Retorna solo el color de texto/icono para un estado (sin badge).
  static Color textColor(String estado) {
    return resolve(estado).textColor;
  }
}
