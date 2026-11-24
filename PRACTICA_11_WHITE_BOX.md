# Práctica 11: Pruebas White Box — MediControl V2

> **Portada de entrega:** el PDF proporcionado, `Portada.pdf`, debe ser la primera página del documento final. Esta versión Markdown conserva el contenido técnico editable; el PDF final se genera con esa portada al frente.

**Fecha de revisión:** 10 de noviembre de 2026  
**Versión evaluada:** Git `c113e0f` más las correcciones de esta práctica  
**Equipo:** Windows 11 Home Single Language, Flutter 3.47.9  
**Arquitectura real:** Flutter + Firebase Authentication + Cloud Firestore.

## 1. Alcance y fuentes de evidencia

| Componente | Implementación evaluada | Evidencia técnica |
|---|---|---|
| Aplicación móvil | `AppointmentLogic`, `FirebaseAuthService` y `UserDataService` | Pruebas unitarias, análisis estático y trazas de depuración |
| Autenticación | Firebase Authentication con correo y contraseña | Código fuente, consola Firebase Auth y flujo de inicio de sesión |
| Persistencia | Cloud Firestore con documentos `users/{uid}` y subcolecciones por usuario | Reglas Firestore, consola Firebase y operaciones CRUD |
| API auxiliar | Express/SQLite local | Solo entorno de pruebas auxiliar; no representa el backend de producción ni sus métricas se usan como resultados Firebase |

Comandos de evidencia automatizada:

```powershell
flutter test --coverage test\unit\appointment_logic_test.dart
flutter analyze
```

## 2. Fase 1 — Análisis estático

### Módulos principales

- **Autenticación:** `lib/services/firebase_auth_service.dart` usa `FirebaseAuth.instance` y crea/consulta el documento del usuario en Firestore.
- **Datos del usuario:** `lib/services/user_data_service.dart` almacena citas, contactos, registros médicos y médicos favoritos bajo `users/{uid}`.
- **Seguridad:** `firestore.rules` controla el acceso por UID y rol.
- **Lógica de negocio:** `lib/services/appointment_logic.dart` valida y ordena citas antes de persistirlas.

### Resultados

| Revisión | Resultado |
|---|---|
| `flutter analyze` | Sin incidencias. |
| Pruebas unitarias de citas | 4/4 aprobadas. |
| Cobertura de instrucciones de `appointment_logic.dart` | 20/22 = **90.91%**. |
| Credenciales | No se encontraron contraseñas ni claves privadas en el código inspeccionado. La configuración de Firebase contiene identificadores públicos de proyecto, no secretos. |

### Defecto corregido: reglas para subcolecciones

La app escribe en rutas como `users/{uid}/appointments/{appointmentId}`, pero las reglas anteriores solo declaraban colecciones superiores independientes. Las reglas de un documento padre no se heredan automáticamente a sus subcolecciones; por tanto, Firestore podía rechazar estas operaciones.

Se agregaron reglas explícitas de lectura/escritura para:

- `users/{uid}/appointments`
- `users/{uid}/emergency_contacts`
- `users/{uid}/medical_records`
- `users/{uid}/favorite_doctors`

Cada una exige usuario autenticado y coincidencia entre `request.auth.uid` y el `{uid}` de la ruta.

## 3. Fase 2 — White Box de aplicación móvil

### Método 1: `AppointmentLogic.validateAppointment`

```text
Inicio -> trim de 4 campos -> ¿algún campo vacío?
                                  | sí -> error de campos -> Fin
                                  no
                                    -> ¿fecha anterior a ahora - 1 min?
                                         | sí -> error de fecha -> Fin
                                         no -> resultado válido -> Fin
```

| Camino independiente | Caso automatizado | Resultado |
|---|---|---|
| P1 | Campos completos y fecha futura | Válido |
| P2 | Doctor vacío | Rechazado |
| P3 | Especialidad vacía | Rechazado |
| P4 | Ubicación vacía | Rechazado |
| P5 | Motivo vacío | Rechazado |
| P6 | Fecha pasada por más de un minuto | Rechazado |
| P7 | Fecha dentro del margen de un minuto | Válido |

### Métodos 2 y 3

| Método | Caminos ejecutados | Resultado |
|---|---|---|
| `sortChronologically` | Lista invertida con dos fechas separadas por un minuto | Orden ascendente correcto |
| `findNextAppointment` | Lista vacía, solo vencidas y mezcla de vencida/futura | `null`, `null` y próxima cita, respectivamente |

| Técnica | Evidencia |
|---|---|
| Cobertura de instrucciones | 90.91% de `appointment_logic.dart` |
| Cobertura de decisiones | Ramas de campos, fecha pasada y fecha admisible ejecutadas |
| Cobertura de condiciones | Cada campo obligatorio se probó vacío individualmente |
| Valores límite | Fecha exactamente en el margen de un minuto |
| Excepciones/errores | Entradas incompletas y fechas no permitidas |

No se declara 100%: la guarda defensiva de mes en `formatDate` no es alcanzable con una instancia `DateTime` válida, ya que Dart normaliza meses fuera de rango.

## 4. Fase 3 — Firebase Authentication y Firestore

Firestore se consume mediante SDK, no mediante una API REST propia. Por ello, la evidencia se registra mediante el resultado de `FirebaseAuthException`, `FirebaseException`, el estado de la operación y la verificación del documento en Firestore; no se deben inventar códigos HTTP.

| ID | Operación | Resultado esperado | Evidencia requerida |
|---|---|---|---|
| FB-01 | Iniciar sesión con cuenta válida | Usuario autenticado y documento `users/{uid}` cargado | Registro de depuración o consola |
| FB-02 | Inicio con contraseña incorrecta | Mensaje controlado de credencial inválida | Registro de depuración |
| FB-03 | Crear cita válida | Documento creado bajo `users/{uid}/appointments` | Consola Firestore |
| FB-04 | Crear cita con campo vacío | Validación móvil, sin escritura en Firestore | Prueba unitaria o registro |
| FB-05 | Consultar citas | Solo documentos del UID actual y orden ascendente por fecha | Consola y aplicación |
| FB-06 | Eliminar cita propia | Documento eliminado y lista actualizada | Consola Firestore |
| FB-07 | Intentar acceso a UID distinto | `permission-denied` por reglas | Firebase Emulator o entorno de prueba autorizado |

## 5. Fase 4 — Base de datos Cloud Firestore

| Operación | Ruta y criterio de aceptación |
|---|---|
| Inserción válida | `users/{uid}/appointments/{id}` creado por `addAppointment`; confirmar ID y campos en consola. |
| Inserción inválida | `validateAppointment` rechaza la entrada antes de invocar Firestore. |
| Consulta existente | `getUserAppointments` ejecuta `orderBy('date')` y omite documentos de inicialización. |
| Consulta inexistente | Una subcolección vacía devuelve lista vacía, no una operación exitosa falsa. |
| Eliminación | `deleteAppointment` borra el documento identificado. |
| Persistencia | Cerrar y abrir la pantalla; la consulta de Firestore debe devolver la cita previamente creada. |
| Concurrencia | Ejecutar dos escrituras simultáneas solo en entorno de prueba; registrar IDs distintos y verificar que no haya duplicados lógicos. |

Firestore no ofrece `EXPLAIN` de consultas. La evidencia equivalente es la configuración de índices en Firebase Console y las métricas de Firestore Usage. Para consultas complejas que requieran un índice compuesto, la consola provee el enlace de creación.

## 6. Fase 5 — Rendimiento y conectividad

Las métricas previamente obtenidas contra Express/SQLite local quedan clasificadas como **anexo de laboratorio** y no se usan para evaluar Firebase. Para completar la evidencia real, ejecuta las mediciones siguientes con una cuenta de prueba y registra valores observados:

| Métrica | Procedimiento | Evidencia técnica |
|---|---|---|
| Latencia Firestore | Medir con `Stopwatch` el intervalo de `addAppointment`, `getUserAppointments` y `deleteAppointment` | Log con 10 iteraciones por operación |
| Tamaño de respuesta | Registrar cantidad de documentos y campos leídos | Log/Firestore Usage |
| Tasa de transferencia | Aplicar `(bytes * 8) / (segundos * 1,000,000)` con tamaño serializado y tiempo observado | Tabla de cálculos |
| Ping | Ejecutar 20 paquetes al host de prueba autorizado | Salida de consola |
| Pérdida de conectividad | Desactivar red antes de crear cita y comprobar error visible/no confirmación falsa | Log de excepción y estado UI |
| Recuperación | Restablecer red y reintentar con identificador de operación; confirmar que no duplica documentos | Firestore Console |

## 7. Defectos, riesgos y propuestas

| ID | Componente | Severidad | Evidencia | Estado/propuesta |
|---|---|---|---|---|
| FB-WB-01 | Firestore Rules | Alta | Las rutas usadas son subcolecciones de `users/{uid}`, sin regla específica previa | **Corregido** en `firestore.rules`; falta desplegar y verificar en Emulator/Firebase. |
| FB-WB-02 | Manejo de errores | Media | `UserDataService` captura excepciones y retorna listas vacías o `false`, ocultando la causa al usuario | Propagar/registrar `FirebaseException` y mostrar error explícito. |
| FB-WB-03 | Idempotencia | Media | `addAppointment` usa ID automático y no contiene una clave de operación reintentable | Añadir `clientRequestId` único y consultar/escribir mediante transacción si se habilitan reintentos. |
| FB-WB-04 | Evidencia de rendimiento | Media | No hay métricas reales de Firebase en este equipo | Ejecutar la tabla de 10 iteraciones en proyecto Firebase de prueba. |

## 8. Respuestas individuales

1. La cobertura de instrucciones cuenta líneas ejecutadas; la de decisiones cubre salidas verdadero/falso; la de condiciones ejecuta cada operando. En `validateAppointment`, se cubren los cuatro campos y las decisiones de fecha.
2. `validateAppointment` concentra la complejidad por sus condiciones compuestas. Si crece sin extraer validadores, aumenta el número de rutas y el riesgo de pruebas incompletas.
3. Ping mide ICMP; una operación Firestore agrega TLS, SDK, autenticación, reglas, red y persistencia.
4. Un ping bajo y una operación lenta pueden deberse a autenticación, evaluación de reglas, radio móvil, serialización, cold start o carga del servicio.
5. JSON/documentos grandes consumen red, memoria y CPU; se deben seleccionar solo campos y paginar resultados.
6. Si se pierde red tras enviar una escritura, el cliente no sabe de inmediato si Firestore la confirmó; debe mostrar estado pendiente o comprobar la operación.
7. Una clave `clientRequestId` única y una transacción evitan crear dos documentos al reintentar.
8. Una transacción protege la atomicidad: todos los cambios se confirman juntos o ninguno.
9. Firestore se ejecuta en nube y está sujeto a red, reglas e índices; el SDK es distinto de una consulta local y debe medirse desde la aplicación.
10. El posible cuello de botella actual es la red/Firestore, pues aún no hay métricas reales de ese entorno. La conclusión debe basarse en las 10 mediciones solicitadas, no en la prueba SQLite auxiliar.

## 9. Limitaciones declaradas

- No se desplegaron reglas ni se modificaron datos de un proyecto Firebase remoto desde esta auditoría.
- La prueba de desconexión y los datos de rendimiento Firebase están pendientes de ejecución con una cuenta de prueba.
