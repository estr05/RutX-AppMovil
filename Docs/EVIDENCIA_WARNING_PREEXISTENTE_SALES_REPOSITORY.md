# Evidencia: warning preexistente en `sales_repository.dart:309` (fuera del alcance Cloudflare)

## Síntoma

`flutter analyze` reporta 1 issue durante la fase Cloudflare Tunnel:

```
warning - The '!' will have no effect because the receiver can't be null
  - lib/features/sales/data/sales_repository.dart:309:21
  - unnecessary_non_null_assertion
```

## Reproducción contra la base limpia (preexistente)

Con los cambios de la fase guardados temporalmente (`git stash`), el análisis
del archivo aislado produce exactamente el mismo resultado:

```
> flutter analyze --no-pub lib/features/sales/data/sales_repository.dart
  warning - ... unnecessary_non_null_assertion   (1 issue)

> git stash -q
> flutter analyze --no-pub lib/features/sales/data/sales_repository.dart
  warning - ... unnecessary_non_null_assertion   (1 issue)   <- base limpia
> git stash pop -q
```

El archivo no fue modificado por la fase: **el warning es preexistente**.

## Decisión

* No se excluye ni silencia nada (`// ignore:` NO se agregó).
* No se corrige aquí: tocar `sales_repository.dart` escapa al alcance de esta
  fase y merece su propio commit con prueba de no-regresión.
* Queda registrado como deuda técnica conocida para abordarse por separado.
