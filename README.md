# Investment Tracking — App Flutter

Aplicación móvil y de escritorio para el seguimiento de carteras de inversión. Permite registrar activos financieros, añadir transacciones de compra, consultar el P&L en tiempo real y funcionar sin conexión con sincronización automática al recuperar la red.

---

## Índice

1. [Requisitos previos](#requisitos-previos)
2. [Configuración del entorno](#configuración-del-entorno)
3. [Configuración del backend](#configuración-del-backend)
4. [Ejecutar la aplicación](#ejecutar-la-aplicación)
5. [Ejecutar los tests](#ejecutar-los-tests)
6. [Estructura del proyecto](#estructura-del-proyecto)
7. [Aspectos técnicos destacados](#aspectos-técnicos-destacados)

---

## Requisitos previos

| Herramienta            | Versión mínima                |
| ---------------------- | ----------------------------- |
| Flutter SDK            | 3.x (Dart >= 3.9)             |
| Android Studio / Xcode | Para emuladores móviles       |
| Backend Spring Boot    | Corriendo en `localhost:8080` |

Instalar Flutter siguiendo la [guía oficial](https://docs.flutter.dev/get-started/install).

En Linux (Ubuntu/Debian), instalar las dependencias de escritorio antes de la primera ejecución:

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

---

## Configuración del entorno

```bash
# Clonar el repositorio
git clone git@github.com:SilviaGarciaBouza/Fronted_Investment_Tracking.git
cd Fronted_Investment_Tracking

# Instalar dependencias de Flutter
flutter pub get
```

### URL del backend

La URL base de la API está definida en `lib/service/api_service.dart`:

```dart
final String baseUrl = "http://localhost:8080/api";
```

Cambiar este valor si el backend corre en una dirección o puerto diferente. Para Android en emulador, usar `http://10.0.2.2:8080/api` en lugar de `localhost`.

## Ejecutar la aplicación

```bash
# Android (emulador o dispositivo físico)
flutter run -d android

# iOS (requiere macOS y Xcode)
flutter run -d ios

# Linux (escritorio)
flutter run -d linux

# macOS (escritorio, requiere Xcode)
flutter run -d macos
```

> **Nota:** la plataforma web no está soportada porque `sqflite` no tiene backend web. La app usa SQLite para el modo offline y no tiene un sustituto en-navegador.

Para listar los dispositivos disponibles en el sistema:

```bash
flutter devices
```

### Builds de producción

```bash
flutter build apk
flutter build ipa
```

---

## Ejecutar los tests

La suite completa de tests no necesita dispositivo ni backend: todo el acceso a red va mockeado y SQLite corre en memoria mediante `sqflite_ffi`.

```bash
# Tests unitarios (un fichero por clase)
flutter test test/unitTest/

# Tests de integración (composición de capas)
flutter test test/integrationTest/

# Un único fichero
flutter test test/unitTest/models/item_test.dart
```

Los tests E2E del sistema requieren un dispositivo conectado y el backend corriendo:

```bash
flutter test -d linux integration_test/system_integration_test.dart
```

---

## Estructura del proyecto

```
lib/
├── main.dart                        # Punto de entrada, rutas y provider raíz
├── models/                          # Entidades de dominio
│   ├── item.dart                    # Activo financiero con sus transacciones
│   ├── transaction.dart             # Movimiento de compra individual
│   ├── user.dart                    # Usuario autenticado con token JWT
│   └── category.dart                # Clasificación de activos
├── viewmodels/
│   └── Inv_viewmodel.dart           # ViewModel único (ChangeNotifier) con todo el estado
├── repositories/                    # Acceso a datos: API primero, SQLite como fallback
│   ├── item_repository.dart
│   ├── Transaction_repository.dart
│   ├── auth_repository.dart
│   ├── category_repository.dart
│   └── session_repository.dart
├── dao/                             # CRUD directo sobre SQLite, un DAO por tabla
│   ├── item_dao.dart
│   ├── transaction_dao.dart
│   ├── user_dao.dart
│   └── caegory_dao.dart
├── database/
│   └── database_helper.dart         # Singleton SQLite, schema v20
├── exceptions/                      # Excepciones de dominio para errores HTTP y de red
│   ├── server_http_exception.dart
│   ├── Server_unavailable_exception.dart
│   └── Unauthorized_exception.dart
├── service/
│   ├── api_service.dart             # Cliente HTTP con timeout de 30 s y cabeceras JWT
│   ├── storage_service.dart         # SharedPreferences
│   └── SettingsService.dart         # Persistencia de tema e idioma
├── theme/
│   └── app_theme.dart               # Tema claro/oscuro de la aplicación
├── views/                           # Pantallas de la aplicación
│   ├── login_view.dart
│   ├── register_view.dart
│   ├── home_view.dart
│   ├── add_transaction.dart
│   ├── transaction_detail_view.dart
│   ├── total_view.dart
│   └── splash_view.dart
├── utils/
│   ├── app_strings.dart             # Internacionalización (es / gl / en)
│   └── network_error_utils.dart     # Helpers para clasificar errores de red
└── widgets/                         # Componentes reutilizables
    └── build_summary_row.dart
```

---

## Aspectos técnicos destacados

### Arquitectura MVVM + Repository + DAO

El proyecto aplica una separación de responsabilidades en tres capas:

- **Views** consumen el `InvViewModel` mediante `Consumer<InvViewModel>` y no conocen la fuente de datos.
- **Repositories** intentan el servidor primero y caen a SQLite si falla, marcando los registros pendientes con `isSynced = 0`.
- **DAOs** ejecutan SQL puro sobre sqflite, sin lógica de negocio.

Esta separación hace que cambiar la fuente de datos (por ejemplo, sustituir SQLite por otro motor) solo afecte a los DAOs, sin tocar el ViewModel ni las vistas.

### Modo offline-first con sincronización automática

Todas las escrituras tocan SQLite primero. Los registros no sincronizados se marcan con `is_synced = 0` o `is_deleted = 1` y se suben al servidor en cuanto se recupera la conexión. El `InvViewModel` ejecuta `syncPendingData()` automáticamente al reconectarse, garantizando que ninguna operación offline se pierda.

### Detección de conectividad en dos niveles

La app combina `connectivity_plus` (paquete Flutter que escucha los eventos de red del sistema operativo: conexión/desconexión de WiFi, datos móviles, etc.) con una verificación activa contra el servidor cada 20 segundos. Esto evita el problema habitual de confundir "hay WiFi" con "el backend está accesible": es posible tener red pero que el servidor esté caído, y la app lo detecta correctamente.

Cuando `connectivity_plus` detecta reconexión, el ViewModel espera 2 segundos antes de confirmar la disponibilidad del backend y lanzar la sincronización pendiente, evitando falsos positivos en conexiones inestables.

### P&L calculado como getters derivados

Las métricas financieras (`totalCurrentValue`, `totalInvestment`, `totalPnL`, `totalPnLPercent`) son getters calculados en tiempo real a partir del estado, sin persistirlos. Cualquier cambio en precios o transacciones se refleja de inmediato en toda la UI gracias al sistema reactivo de `ChangeNotifier`.

### Exportación de informes en PDF

El `InvViewModel` incluye un método `generatePdfReport` que genera un informe A4 de la cartera (activos, transacciones y métricas P&L) usando los paquetes `pdf` y `printing`. El informe se construye en memoria y se ofrece al usuario para guardar o compartir directamente desde la app, sin pasar por el servidor.

### Internacionalización sin paquetes externos

El sistema de traducción es un mapa estático en `lib/utils/app_strings.dart` que soporta español, gallego e inglés. El idioma se detecta automáticamente del sistema operativo y puede cambiarse desde la app, persistiéndose en SharedPreferences.

### Suite de tests estructurada en tres niveles

| Nivel                 | SQLite                 | HTTP           | Qué verifica                                         |
| --------------------- | ---------------------- | -------------- | ---------------------------------------------------- |
| Unitario              | Mockeado / real ffi    | Mockeado       | Cada clase de forma aislada                          |
| Integración bottom-up | Real (sqflite_ffi)     | Mockeado       | DAO -> Repository -> ViewModel con asserts en SQLite |
| Integración top-down  | Real (infraestructura) | Mockeado       | Flujos completos desde el ViewModel hacia abajo      |
| E2E sistema           | Real                   | Real (backend) | Stack completo desde la UI hasta el servidor         |

Los tests de integración usan una base de datos SQLite separada para evitar colisiones con la base de datos de la app. La concurrencia está configurada con `concurrency: 1` en `dart_test.yaml` para evitar errores `SQLITE_BUSY`.

### Soporte multiplataforma con un único código base

La misma app corre en Android, iOS, Linux y macOS. La diferencia principal está en la inicialización de SQLite: en escritorio (Linux, macOS, Windows) se usa `sqflite_common_ffi` y en móvil el `sqflite` estándar, con la detección de plataforma encapsulada en `database_helper.dart`. La plataforma web no está soportada porque `sqflite` no tiene backend web.
