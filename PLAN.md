# PLAN DEFINITIVO - Paginación y Robustez UI

## Contexto y Análisis
Al restaurar el archivo `clientes_page.dart` en la iteración anterior para quitar el `Scaffold`, **se sobrescribieron accidentalmente las correcciones de datos originales** (`getFirst(100)` y `ventaDao.getAll()`). Además, se diagnosticó que el Cuadro Gris en modo Release es originado por un **Crash de Renderizado (RangeError)** cuando un nombre de cliente es muy corto o tiene espacios múltiples, o cuando la fechaHora es anómala, haciendo que Flutter aborte el `ListView`.

## Requerimiento del Usuario
Implementar "Lógica de programación del flujo" (Paginación UI):
- Carga inicial: limit 10
- Scroll Listener para sobre-desplazamiento
- Indicador CircularProgressIndicator temporal
- Concatenación del estado local.

## Plan de Acción

1. **Restaurar las correcciones de DAO**:
   - Quitar el límite artificial de `getFirst(100)` y usar `getAll()`.
   - Limitar el `_visitasMap` solo a las ventas de `hoy` con `getDelDia(hoy)`.
   - Cambiar `print` por `debugPrint`.

2. **Implementar Paginación UI (Infinite Scroll)**:
   - Crear variables de estado: `_displayLimit = 10`, `_isLoadingMore = false`.
   - Implementar `ScrollController` y el listener `_onScroll`.
   - Modificar el renderizado para tomar `.take(_displayLimit)` de la lista filtrada.
   - Agregar un item adicional al `ListView.builder` para mostrar el `CircularProgressIndicator` cuando `_isLoadingMore` es true.

3. **Blindar los Extractores de Strings (Prevenir Cuadro Gris)**:
   - Crear una lógica segura para extraer `initials` (verificando `length` y evitando crashes por arrays vacíos debido a múltiples espacios).
   - Crear una lógica segura para extraer la hora `substring(11, 16)`, verificando primero que la longitud del string `fechaHora` sea al menos 16.

4. **Regenerar APK y Validar**.
