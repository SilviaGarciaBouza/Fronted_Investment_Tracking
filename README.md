# 🚀 My Investment Portfolio Tracker (Web-First)

Una aplicación de gestión y seguimiento de inversiones multi-activo, desarrollada con **Flutter (Dart)**, que utiliza una única base de código para ofrecer una experiencia profesional y persistente tanto en la **Web** como en dispositivos móviles y de escritorio.

## 🌟 Características Principales

### 📈 Gestión Financiera Avanzada

- **Coste Promedio Ponderado (WAC):** Implementación de lógica avanzada para calcular automáticamente el coste promedio (`Share Prize`) al realizar múltiples compras del mismo activo.
- **Seguimiento en Tiempo Real:** Obtiene precios de mercado (Acciones, FX, Cripto) de la API de Alpha Vantage para calcular el **Valor Actual Total** y el **Pérdida/Ganancia (P&L)** de toda la cartera.
- **Desglose de Transacciones:** La vista `TransactionDetailView` permite a los usuarios examinar cada compra individual y su impacto actual en el P&L, basada en el precio de mercado.
- **Cálculo de Totales:** Muestra un resumen financiero completo de la cartera (Inversión Total, Valor Actual Total, P&L Absoluto y Porcentual).

### 💾 Estabilidad y Multiplataforma

- **Aplicación Multiplataforma (Web-First):** Una única base de código desplegable en **Web**, iOS, Android, Windows, macOS y Linux.
- **Persistencia Adaptativa:** Utiliza **`shared_preferences`** para guardar la cartera. En la web, esta librería se adapta automáticamente para usar el **`localStorage` del navegador**, asegurando que los datos persistan en el cliente.
- **Estado de Carga:** Muestra un indicador (`CircularProgressIndicator`) al cargar la aplicación y actualizar los precios de mercado.

## 🛠️ Tecnologías y Arquitectura

- **Framework:** Flutter 3.x (Dart)
- **Arquitectura:** Model-View-ViewModel (MVVM) con **Provider** (`ChangeNotifier`) para gestionar el estado y la lógica de negocio (`Invviewmodel.dart`).
- **Persistencia:** `shared_preferences` (Serialización/Deserialización de objetos Dart a JSON).
- **API Externa:** Alpha Vantage (Cotizaciones).

---

## 🚀 Instalación y Ejecución

### Requisitos

- Tener instalado **Flutter SDK**.
- Tener configurados los toolchains necesarios para la plataforma de destino (ej., Xcode para iOS/macOS, Visual Studio para Windows).
- Clave API de Alpha Vantage.

### Pasos Generales

1.  **Clonar el repositorio:**

    ```bash
    git clone [https://docs.github.com/es/repositories/creating-and-managing-repositories/quickstart-for-repositories](https://docs.github.com/es/repositories/creating-and-managing-repositories/quickstart-for-repositories)
    cd investment_tracking
    ```

2.  **Configurar la API Key:**

    - Inserta tu clave de Alpha Vantage en el archivo `lib/service/StockService.dart`.

3.  **Obtener dependencias:**
    ```bash
    flutter pub get
    ```

### Comandos de Ejecución por Plataforma

Antes de ejecutar, asegúrate de que el soporte para la plataforma de escritorio esté habilitado: `flutter config --enable-windows-desktop`, `flutter config --enable-macos-desktop`, etc.

| Plataforma                | Comando de Ejecución (Debug)   | Comandos de Build (Release)                                |
| :------------------------ | :----------------------------- | :--------------------------------------------------------- |
| **Web**                   | `bash flutter run -d chrome `  | `bash flutter build web ` _(Genera la carpeta /build/web)_ |
| **Android**               | `bash flutter run -d android ` | `bash flutter build apk `                                  |
| **iOS** (macOS necesario) | `bash flutter run -d ios `     | `bash flutter build ipa `                                  |
| **Windows**               | `bash flutter run -d windows ` | `bash flutter build windows ` _(Requiere VS)_              |
| **macOS**                 | `bash flutter run -d macos `   | `bash flutter build macos `                                |
| **Linux**                 | `bash flutter run -d linux `   | `bash flutter build linux `                                |

---

## ⚙️ Estructura del Código

El corazón de la lógica de negocio, persistencia, WAC y llamadas a la API reside en el _ViewModel_:

| Archivo                                | Responsabilidad Principal                                                                       |
| :------------------------------------- | :---------------------------------------------------------------------------------------------- |
| `lib/viewmodels/Invviewmodel.dart`     | Inicialización, Carga/Guardado, WAC (Coste Promedio), Recálculo de P&L y Notificación de la UI. |
| `lib/models/Item.dart`                 | Modelo de Posición Total. Contiene la lista de **Transacciones**.                               |
| `lib/views/Homeview.dart`              | Vista principal de la tabla y navegación.                                                       |
| `lib/views/TransactionDetailView.dart` | Desglose de P&L por compra individual.                                                          |

---

### 👨‍💻 Autor

Silvia García Bouza
