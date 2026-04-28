# FinanSmart

Base profesional en Flutter para una app de finanzas personales orientada a proyecto universitario de grado. El proyecto usa arquitectura `feature-first`, estado con `Provider`, datos mock locales y una estructura lista para crecer hacia Firebase.

## Estado Firebase

La base Firestore ya esta modelada en el proyecto con:

- modelos serializables para Firestore
- repositorios listos para `FirebaseAuth` y `CloudFirestore`
- `firestore.rules`
- `firestore.indexes.json`
- modo fallback mock para seguir corriendo sin configuracion Firebase

El switch actual vive en `lib/core/constants/app_environment.dart`:

```dart
static const bool useFirebase = false;
```

Cuando completes la configuracion real de Firebase, cambialo a `true`.

## Arbol principal

```text
lib/
  core/
    constants/
    routes/
    theme/
    utils/
  shared/
    models/
    services/
    widgets/
  features/
    auth/
      data/
      presentation/
    dashboard/
      data/
      presentation/
    transactions/
      data/
      presentation/
    financial_products/
      data/
      presentation/
    financial_health/
      data/
      presentation/
    reports/
      data/
      presentation/
    profile/
      data/
      presentation/
  main.dart
```

## Dependencias incluidas

- `provider`
- `intl`
- `fl_chart`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `pdf`
- `printing`
- `uuid`

## Como ejecutar

1. Instala Flutter estable y verifica con `flutter --version`.
2. Entra al proyecto:

```bash
cd finansmart_app
```

3. Descarga dependencias:

```bash
flutter pub get
```

4. Ejecuta analisis estatico:

```bash
flutter analyze
```

5. Corre la app en Android:

```bash
flutter run
```

## Estado actual

- Navegacion completa desde `SplashScreen` hasta `HomeScreen`.
- Dashboard financiero con resumen, alertas y grafica.
- Registro local de ingresos y gastos.
- Gestion mock de tarjetas y prestamos.
- Pantalla de salud financiera.
- Reportes mensuales con exportacion PDF e impresion.
- Perfil con configuracion basica y cierre de sesion.

## Integracion manual pendiente

Firebase todavia no esta conectado. Para habilitarlo despues:

1. Ejecuta `flutterfire configure`.
2. Agrega `google-services.json` en `android/app/`.
3. Genera `firebase_options.dart`.
4. Si usaras Web o Apple platforms, inicializa `Firebase.initializeApp` con las opciones generadas.
5. Cambia `useFirebase` a `true` en `lib/core/constants/app_environment.dart`.

## Enfoque de arquitectura

- `core`: tema, constantes, rutas y utilidades globales.
- `shared`: modelos, widgets reutilizables y servicios comunes.
- `features`: cada modulo encapsula su capa de datos y presentacion.
- Providers desacoplados de la UI y preparados para crecer hacia casos de uso o repositorios remotos.
