# FinanSmart

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Academic Project](https://img.shields.io/badge/Academic_Project-FinanSmart-blue)

FinanSmart es una aplicación móvil de finanzas personales desarrollada con Flutter, Dart y Firebase. Su objetivo es ayudar a los usuarios a registrar, organizar y consultar sus ingresos y gastos desde una interfaz móvil clara y responsive.

## Descripción del proyecto

FinanSmart nace como una solución académica y de portafolio para centralizar la gestión básica de finanzas personales. La aplicación permite controlar ingresos, registrar gastos, organizar movimientos por categoría y moneda, y construir una base sólida para futuros reportes financieros, presupuestos y análisis de salud financiera.

El proyecto usa Firebase Authentication para la autenticación real de usuarios y Cloud Firestore para persistir las transacciones asociadas a cada cuenta mediante `userId`.

## Funcionalidades implementadas

- Registro de usuarios con Email/Password.
- Inicio de sesión con Email/Password.
- Persistencia de sesión autenticada.
- CRUD de transacciones conectado a Cloud Firestore.
- Crear ingresos.
- Crear gastos.
- Listar movimientos del usuario autenticado.
- Editar movimientos existentes.
- Eliminar movimientos.
- Filtros por tipo de movimiento: ingresos, gastos o todos.
- Filtros por moneda: DOP, USD o todas.
- Asociación de datos por usuario mediante `userId`.
- Interfaz móvil responsive.
- Repositorio preparado para uso público sin archivos sensibles de Firebase.

## Funcionalidades en desarrollo

- Dashboard dinámico basado en datos reales.
- Reportes financieros mensuales.
- Presupuestos por categoría.
- Gestión de productos financieros.
- Indicadores de salud financiera.
- Exportación de reportes.
- Gráficos financieros avanzados.
- Pruebas unitarias e integración.

## Tecnologías utilizadas

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Provider
- FlutterFire CLI
- Firebase CLI
- Git y GitHub
- Android SDK

## Arquitectura y estructura del proyecto

El proyecto sigue una organización por funcionalidades, separando módulos principales, componentes compartidos y configuración central.

```text
lib/
├── core/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── transactions/
│   ├── reports/
│   ├── budgets/
│   ├── categories/
│   ├── financial_health/
│   ├── financial_products/
│   └── profile/
├── shared/
└── main.dart
```

## Módulos principales

### Auth

Gestiona el registro, inicio de sesión, cierre de sesión y estado del usuario autenticado usando Firebase Authentication.

### Transactions

Permite crear, listar, editar y eliminar ingresos y gastos reales almacenados en Cloud Firestore. Cada transacción se guarda con el `userId` del usuario autenticado.

### Dashboard

Módulo visual para mostrar resúmenes financieros. Actualmente está preparado para evolucionar hacia cálculos dinámicos basados en transacciones reales.

### Reports

Módulo destinado a reportes financieros mensuales, totales por categoría, balance neto y análisis de gastos.

### Financial Products

Módulo proyectado para registrar productos financieros como cuentas, tarjetas, préstamos u otros instrumentos asociados al usuario.

## Modelo principal de datos

Una transacción contiene los siguientes campos principales:

```text
id
userId
type
amount
currency
description
categoryId
categoryName
accountName
paymentMethod
financialProductId
notes
attachmentUrl
transactionDate
createdAt
updatedAt
```

Campos clave:

- `id`: identificador del documento en Firestore.
- `userId`: identificador del usuario autenticado.
- `type`: tipo de movimiento, `income` o `expense`.
- `amount`: monto de la transacción.
- `currency`: moneda, por ejemplo `DOP` o `USD`.
- `description`: descripción del movimiento.
- `categoryId`: identificador de categoría.
- `categoryName`: nombre visible de la categoría.
- `transactionDate`: fecha del movimiento.
- `createdAt`: fecha de creación del documento.
- `updatedAt`: fecha de última actualización.

## Estructura de Firestore

Colecciones previstas o utilizadas por la aplicación:

```text
users
transactions
financial_products
budgets
categories
monthly_reports
financial_health
```

La colección actualmente más importante es `transactions`, donde cada documento se asocia al usuario autenticado mediante el campo `userId`.

## Seguridad y archivos privados

Este repositorio público no incluye archivos locales o sensibles de configuración. Cada desarrollador debe generar su propia configuración de Firebase localmente.

Archivos ignorados por seguridad o configuración local:

```text
lib/firebase_options.dart
android/app/google-services.json
android/local.properties
.env
*.jks
*.keystore
key.properties
```

Aunque la configuración cliente de Firebase no suele considerarse un secreto de servidor, se mantiene fuera del repositorio para evitar exponer detalles del proyecto Firebase en un repositorio público.

## Requisitos previos

Antes de ejecutar el proyecto, instala y configura:

- Flutter SDK
- Dart SDK
- Android Studio o Android SDK
- Firebase CLI
- FlutterFire CLI
- Git

Verifica Flutter con:

```bash
flutter --version
```

## Instalación

Clona el repositorio:

```bash
git clone <URL_DEL_REPOSITORIO>
```

Entra al proyecto:

```bash
cd FinanSmart
```

Instala las dependencias:

```bash
flutter pub get
```

## Configuración de Firebase

Como los archivos de configuración Firebase están ignorados, cada entorno local debe generarlos nuevamente.

1. Crea un proyecto en Firebase Console.
2. Habilita Firebase Authentication.
3. Activa el proveedor Email/Password.
4. Crea una base de datos en Cloud Firestore.
5. Instala FlutterFire CLI si no lo tienes:

```bash
dart pub global activate flutterfire_cli
```

6. Configura Firebase en el proyecto:

```bash
flutterfire configure
```

Este comando genera los archivos locales necesarios:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Estos archivos deben permanecer en tu máquina local y no subirse al repositorio público.

## Ejecutar la aplicación

Ejecuta la app en un emulador o dispositivo Android:

```bash
flutter run
```

Comandos útiles de mantenimiento:

```bash
flutter clean
flutter pub get
flutter analyze
```

## Flujo básico de prueba

1. Crear una cuenta nueva.
2. Iniciar sesión con Email/Password.
3. Crear un ingreso.
4. Crear un gasto.
5. Ver los movimientos en la lista.
6. Filtrar por tipo o moneda.
7. Editar un movimiento.
8. Eliminar un movimiento.
9. Cerrar y volver a abrir la app.
10. Confirmar que los datos persisten desde Firestore.

## Estado actual del proyecto

FinanSmart ya cuenta con:

- Autenticación real con Firebase Authentication.
- Registro e inicio de sesión funcionales.
- Firestore conectado correctamente.
- CRUD real de transacciones.
- Movimientos asociados al usuario autenticado.
- Filtros por tipo y moneda.
- Repositorio público preparado para no subir configuración sensible de Firebase.

## Próximos pasos técnicos

- Conectar el dashboard a cálculos reales.
- Implementar reportes mensuales con datos de Firestore.
- Implementar presupuestos por categoría.
- Implementar productos financieros reales.
- Mejorar reglas de seguridad de Firestore.
- Agregar pruebas unitarias.
- Agregar pruebas de widgets.
- Incluir capturas de pantalla del flujo principal.
- Preparar una licencia formal si el proyecto se publica como open source.

## Autor

Santiago Nathanael Lara

## Licencia

Proyecto académico desarrollado con fines educativos y de portafolio. Se puede agregar una licencia MIT u otra licencia open source en una etapa posterior si se desea distribuir formalmente.
