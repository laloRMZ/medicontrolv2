# Prácticas 13 y 14: Automatización de Pruebas y Validación Continua — MediControl V2

> **Portada de entrega:** El archivo `Portada.pdf` se integra como primera página del entregable final (`PRACTICA_13_14_AUTOMATIZACION_CI_ENTREGA.pdf`).

**Fecha:** 17 de noviembre de 2026  
**Repositorio:** `laloRMZ/medicontrolv2` (rama `main`, commit `25a772e`)  
**Entorno local:** Windows 11, Flutter 3.47.9 (Dart 3.13.7), Node.js  
**Entorno CI:** GitHub Actions (`ubuntu-latest`), workflow `.github/workflows/ci.yml`

---

## Fase 1. Selección de componentes críticos

A partir de las prácticas previas, se seleccionaron tres componentes críticos y sus riesgos prevenibles mediante pruebas automatizadas:

| Categoría | Componente seleccionado | Archivo(s) | Defecto o riesgo prevenible |
|---|---|---|---|
| **Función crítica móvil** | Lógica de negocio de citas (`AppointmentLogic`) | `lib/services/appointment_logic.dart` | Validación incorrecta de fechas pasadas o campos en blanco, desorden cronológico y discrepancia de tipos en IDs (`int` vs `String`). |
| **Servicio / Comunicación** | Cliente REST y manejo de sesión (`ApiService`, `AuthService`) | `lib/services/api_service.dart`, `lib/services/auth_service.dart` | Propagación no controlada de errores HTTP (`500`/`503`), timeouts de red u omisión del header `Authorization: Bearer`. |
| **Persistencia / Almacenamiento** | Sesión local (`SharedPreferences`) y API/SQLite auxiliar | `lib/services/auth_service.dart`, `backend/server.js` | Caída de la app por JSON corrupto en `user_data`, pérdida o falta de limpieza al cerrar sesión, e inconsistencia en `backend/server.js`. |

---

## Fase 2. Automatización de pruebas unitarias

Se implementaron **6 pruebas unitarias nuevas** en `test/unit/practica13_unit_test.dart` (sumadas a las **4 pruebas** existentes en `test/unit/appointment_logic_test.dart`, total **10 pruebas unitarias**) usando `flutter_test` y `test()`:

| Caso | Aspecto evaluado | Cobertura |
|---|---|---|
| 1 | **Entrada válida** | `AppointmentLogic.validateAppointment` acepta campos con espacios laterales (`trim`) y `formatDate` retorna `'5 dic 2026'`. |
| 2 | **Entrada vacía o nula** | Rechaza campos vacíos/blancos, `findNextAppointment([])` retorna `null` y `AuthService.getStoredUser()` retorna `null` sin sesión. |
| 3 | **Valores fuera de rango** | Rechaza fecha pasada fuera del margen de 1 minuto (`-2 min`) y `AuthService.isTokenExpired()` retorna `true` con JWT malformado. |
| 4 | **Resultado esperado** | `sortChronologically` ordena cronológicamente sin mutar la lista original y `findNextAppointment` selecciona la cita futura más cercana. |
| 5 | **Manejo de excepciones (JSON)** | `AuthService.getStoredUser()` captura `FormatException` ante JSON corrupto en `SharedPreferences` y retorna `null`. |
| 6 | **Manejo de excepciones (HTTP)** | `ApiService.fetchProfile()` lanza `Exception` descriptiva con código `500` ante fallo del servidor. |

---

## Fase 3. Automatización de pruebas de integración

Se implementaron **4 pruebas de integración Flutter** en `test/integration/api_persistence_integration_test.dart` (con `HttpServer` efímero real en `127.0.0.1:0` y `SharedPreferences` en memoria), complementadas por **3 pruebas de integración backend** en `backend/test/appointments_integration.test.js` (Express + SQLite real):

1. **Comunicación Cliente-Servicio (`AUT-04`):** `ApiService.fetchAppointments()` envía `Authorization: Bearer <token>` desde `AuthService.getAuthHeaders()`, recibe `HTTP 200` y deserializa `List<Appointment>`.
2. **Deserialización de Perfil (`AUT-04`):** `ApiService.fetchProfile()` valida respuesta `HTTP 200` y construye `UserProfile` completo.
3. **Resiliencia ante fallo del servidor (`AUT-05`):** Ante respuesta `HTTP 503`, `ApiService.fetchAppointments()` propaga excepción controlada con código `503` y URL `/api/appointments`.
4. **Persistencia local (`AUT-06`):** `AuthService` guarda/lee `user_data` y `auth_token` en `SharedPreferences` y los elimina correctamente tras `logout()`.
5. **Backend API + SQLite (`AUT-04`/`AUT-06`):** `POST /api/appointments` (`201 Created`) con verificación física en SQLite, rechazo `400`/`404` y CRUD de médicos, contactos y registros médicos.

---

## Fase 4. Automatización del proceso de pruebas (CI)

Se configuró `.github/workflows/ci.yml` con disparo automático en `push` y `pull_request` hacia `main` y `master`, dividido en dos jobs paralelos:
- **`flutter-tests` (`Flutter Analyze & Tests`):** `flutter pub get`, `flutter analyze`, y `flutter test test/unit test/integration --reporter expanded`.
- **`backend-integration-tests` (`Backend API & SQLite Integration Tests`):** `npm install` y `npm test` (`node --test test/appointments_integration.test.js`).

---

## Fase 5. Validación y análisis de resultados

### Resumen de ejecución local y en CI

| Ejecución | Pruebas ejecutadas | Aprobadas | Fallidas | Tiempo total | Estado |
|---|---|---|---|---|---|
| **Local Flutter (`test/unit`, `test/integration`)** | 14 | 14 | 0 | 11.16 s | Aprobado |
| **Local Backend (`npm test`)** | 3 | 3 | 0 | 1.25 s | Aprobado |
| **CI Run #1 (`809d003`, inicial)** | 16 (14 Flutter + 2 Backend) | 12 | 2 (+2 canceladas) | ~59 s | Fallido |
| **CI Run #2 (`ac1b899`, fix backend)** | 17 (14 Flutter + 3 Backend) | 16 | 1 | ~71 s | Parcial |
| **CI Run #3 (`25a772e`, fix unit test)** | **17 (14 Flutter + 3 Backend)** | **17** | **0** | **~75 s** | **Exitoso** |

### Errores encontrados y correcciones aplicadas

1. **Archivos de prueba vacíos locales (`0 bytes`):** `test/unit/retry_policy_test.dart` y `test/unit/ttl_read_cache_test.dart` impedían compilar la suite (`Undefined name 'main'`). Se eliminaron los archivos vacíos remanentes.
2. **Fallo en CI Run #1 — Backend (`appointments_integration.test.js:14`):** `server.js` en `main` no exportaba `{ app, db }`, causando `TypeError` y cancelación de 2 pruebas. **Corrección:** commit `ac1b899` exportando `{ app, db }` en `backend/server.js` y completando las 3 pruebas de integración.
3. **Fallo en CI Run #1 y #2 — Unitaria (`appointment_logic_test.dart:64`):** `expect(sorted.first.id, equals(1))` comparaba `String` `'1'` contra `int` `1`. **Corrección:** commit `25a772e` actualizando las expectativas a `'1'` y `'2'`, logrando **17/17 pruebas aprobadas** en CI Run #3 (`https://github.com/laloRMZ/medicontrolv2/actions/runs/44223354257`).
4. **Observación en `widget_test.dart` y `e2e_appointment_flow_test.dart`:** Fallan en ejecución aislada sin entorno Firebase inicializado (`[core/no-app] No Firebase App '[DEFAULT]' has been created`), por lo que el pipeline CI ejecuta explícitamente las suites `test/unit` y `test/integration` desacopladas de Firebase nativo.

---

## Matriz de Automatización

| ID | Tipo | Descripción / Caso automatizado | Evidencia | Estado |
|---|---|---|---|---|
| **AUT-01** | Unitarias | Validación de cita con entrada válida (`trim`, `formatDate`) y rechazo de campos vacíos o nulos (`AppointmentLogic`, `AuthService.getStoredUser`). | `test/unit/practica13_unit_test.dart` (casos 1 y 2) + `appointment_logic_test.dart` | **Aprobado** |
| **AUT-02** | Unitarias | Validación de valores fuera de rango (fecha pasada `>1 min`, JWT inválido) y resultado esperado (ordenamiento sin mutar lista y próxima cita). | `test/unit/practica13_unit_test.dart` (casos 3 y 4) | **Aprobado** |
| **AUT-03** | Unitarias | Manejo de excepciones: tolerancia a JSON corrupto en `SharedPreferences` y excepción controlada ante HTTP `500` en `ApiService`. | `test/unit/practica13_unit_test.dart` (casos 5 y 6) | **Aprobado** |
| **AUT-04** | Integración | Comunicación `ApiService` -> `AuthService` -> `HttpServer` real (`HTTP 200`, header `Bearer` y deserialización) y `POST /api/appointments` (`201 Created`). | `test/integration/api_persistence_integration_test.dart` + `backend/test/appointments_integration.test.js` | **Aprobado** |
| **AUT-05** | Integración | Manejo de fallo del servidor (`HTTP 503` en `ApiService` y `400`/`404` en API REST) propagando mensajes controlados. | `test/integration/api_persistence_integration_test.dart` (caso 3) + `appointments_integration.test.js` | **Aprobado** |
| **AUT-06** | Persistencia | Almacenamiento, lectura y limpieza de sesión en `SharedPreferences` (`AuthService`) y persistencia física verificada en SQLite (`backend/server.js`). | `test/integration/api_persistence_integration_test.dart` (caso 4) + `appointments_integration.test.js` | **Aprobado** |
| **AUT-07** | CI | Pipeline automático en GitHub Actions (`.github/workflows/ci.yml`) ejecutando `flutter analyze`, `flutter test` y `npm test` en cada `push`/`PR`. | `.github/workflows/ci.yml`, Run #3 (`44223354257`) | **Aprobado** |
| **AUT-08** | CI | Validación continua tras correcciones: detección de fallos en Run #1, corrección en commits `ac1b899` y `25a772e`, y re-ejecución exitosa (17/17). | Runs `44223047503` -> `44223187547` -> `44223354257` | **Aprobado** |

---

## Fase 6. Conclusiones

La automatización de pruebas unitarias, de integración y su ejecución continua en GitHub Actions garantiza que cada cambio integrado en `medicontrolv2` sea validado de forma reproducible y sin intervención manual. Durante esta práctica, el pipeline detectó de inmediato dos regresiones reales que habrían pasado desapercibidas en pruebas manuales aisladas: una inconsistencia de tipos (`int` vs `String`) en `appointment_logic_test.dart` y la falta de exportación de `{ app, db }` en `backend/server.js` en la rama `main`. Al ejecutar automáticamente `flutter analyze`, las 14 pruebas de Flutter y las 3 pruebas de integración del backend en ~75 segundos tras cada `push` o `pull_request`, el equipo obtiene una barrera objetiva contra regresiones funcionales, errores de contrato HTTP y fallos de persistencia, preservando la calidad de la aplicación a lo largo de su evolución.
