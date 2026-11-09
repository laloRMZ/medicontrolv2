# PRÁCTICA 8: Evaluación de Calidad de Software mediante Pruebas de Caja Negra
## MediControl V2 - Black Box Testing

**Proyecto:** MediControl V2 - Sistema de Gestión Médica con Firebase  
**Fecha:** Noviembre 2026  
**Módulos Evaluados:** Autenticación, Perfiles de Usuario, Citas, Registros Médicos, Contactos de Emergencia

---

## 1. INVENTARIO DE FUNCIONALIDADES PRINCIPALES

### Módulo de Autenticación
- Registro de nuevo usuario
- Inicio de sesión con correo y contraseña
- Cierre de sesión
- Recuperación de contraseña
- Validación de sesión activa

### Módulo de Perfil de Usuario
- Ver perfil personal
- Editar información personal (nombre, teléfono, tipo de sangre, alergias)
- Ver historial de cambios
- Consultar datos médicos asociados

### Módulo de Citas Médicas
- Crear nueva cita (fecha, doctor, especialidad, razón)
- Ver lista de citas programadas
- Buscar citas por fecha o doctor
- Modificar estado de cita (Pendiente, En Proceso, Completada)
- Cancelar cita
- Filtrar citas por rango de fechas

### Módulo de Registros Médicos
- Registrar nuevo evento médico (diagnóstico, medicamentos, notas)
- Consultar historial completo
- Buscar registros por fecha o tipo
- Modificar registro existente
- Eliminar registro (con confirmación)
- Exportar información

### Módulo de Contactos de Emergencia
- Agregar contacto de emergencia
- Editar contacto existente
- Eliminar contacto
- Ver lista de contactos
- Validar relación familiar

### Módulo Admin
- Gestión de usuarios (ver, editar, cambiar rol)
- Panel de estadísticas
- Ver auditoría de cambios

---

## 2. REQUISITOS VERIFICABLES

### OPERACIONES PRINCIPALES (4 requisitos)

#### REQ-01: Registro de Nueva Cita Médica
**Funcionalidad:** Crear una cita médica con todos los campos obligatorios  
**Entradas:**
- Nombre del doctor (obligatorio)
- Especialidad médica (obligatorio)
- Fecha y hora (obligatorio, formato YYYY-MM-DD HH:MM)
- Razón de la consulta (obligatorio, 10-500 caracteres)
- Ubicación/clínica (obligatorio)

**Restricciones:**
- La fecha no puede ser anterior a hoy
- La hora debe estar en rango 08:00 - 20:00
- El doctor debe existir en la base de datos
- Máximo 50 citas por usuario por mes

**Salidas Esperadas:**
- Confirmación visual "Cita registrada exitosamente"
- ID de cita generado automáticamente
- Cita aparece inmediatamente en la lista personal

**Criterio de Aceptación:**
- ✅ Cita guardada en Firestore con estado "Pendiente"
- ✅ Usuario puede ver la cita en su lista
- ✅ Mensaje de confirmación visible
- ✅ Timestamp de creación registrado

**Estado de Verificación:** ☐ No verificado

---

#### REQ-02: Modificación de Información de Perfil
**Funcionalidad:** Editar datos personales del usuario  
**Entradas:**
- Nombre completo (2-100 caracteres)
- Teléfono (formato: +CC 10-15 dígitos)
- Tipo de sangre (O+, O-, A+, A-, B+, B-, AB+, AB-)
- Alergias (0-500 caracteres)
- Dirección (5-200 caracteres)

**Restricciones:**
- Al menos el nombre debe cambiar
- Los campos solo se actualizan si pasan validación
- Máximo un cambio de perfil por minuto (anti-spam)

**Salidas Esperadas:**
- Confirmación "Perfil actualizado"
- Datos reflejados inmediatamente en pantalla
- Timestamp de modificación visible

**Criterio de Aceptación:**
- ✅ Documento de usuario actualizado en Firestore
- ✅ Nueva información visible en pantalla
- ✅ Historial de cambios registra la operación
- ✅ Sin mensajes de error

**Estado de Verificación:** ☐ No verificado

---

#### REQ-03: Búsqueda y Filtrado de Citas
**Funcionalidad:** Filtrar citas por rango de fechas y estado  
**Entradas:**
- Fecha inicio (YYYY-MM-DD)
- Fecha fin (YYYY-MM-DD)
- Estado: Pendiente | En Proceso | Completada
- (Opcional) Búsqueda por nombre de doctor

**Restricciones:**
- Rango máximo: 90 días
- Fecha fin debe ser >= fecha inicio
- Solo mostrar citas del usuario autenticado

**Salidas Esperadas:**
- Lista de citas filtradas (0 o más resultados)
- Mensaje "Sin citas" si no hay resultados
- Resultados ordenados cronológicamente

**Criterio de Aceptación:**
- ✅ Solo se muestran citas en el rango especificado
- ✅ El filtrado es instantáneo (<2 segundos)
- ✅ Se muestran los 4 campos principales de cada cita
- ✅ Búsqueda es case-insensitive

**Estado de Verificación:** ☐ No verificado

---

#### REQ-04: Eliminación de Registros Médicos
**Funcionalidad:** Eliminar un registro médico con confirmación  
**Entradas:**
- ID del registro (seleccionado de lista)
- Confirmación del usuario (diálogo SÍ/NO)

**Restricciones:**
- Solo el propietario puede eliminar su registro
- No se pueden recuperar registros eliminados
- Debe mostrarse un diálogo de confirmación

**Salidas Esperadas:**
- Mensaje de confirmación requerido
- Confirmación de eliminación "Registro eliminado"
- Registro desaparece de la lista

**Criterio de Aceptación:**
- ✅ Documento eliminado de Firestore
- ✅ No aparece en futuras consultas
- ✅ Diálogo de confirmación mostrado
- ✅ Operación registrada en auditoría

**Estado de Verificación:** ☐ No verificado

---

### VALIDACIONES (3 requisitos)

#### REQ-05: Validación de Formato de Teléfono
**Funcionalidad:** Rechazar teléfonos con formato inválido  
**Entradas Válidas:**
- +57 1234567890
- +1-555-0100
- +34 91 555 0100

**Entradas Inválidas:**
- abc123
- 12345
- +57 1234
- (vacío)

**Salida Esperada:**
- Mensaje de error: "El teléfono debe incluir código de país y 10-15 dígitos"
- Campo resaltado en rojo
- Botón de guardar deshabilitado

**Criterio de Aceptación:**
- ✅ No se acepta el formato inválido
- ✅ Error visible y legible
- ✅ Campo puede editarse para corregir
- ✅ Validación es inmediata (mientras escribe)

**Estado de Verificación:** ☐ No verificado

---

#### REQ-06: Rechazo de Fecha de Cita Pasada
**Funcionalidad:** Impedir crear citas con fechas anteriores a hoy  
**Escenarios:**
1. Fecha: 2026-01-01 (pasada)
2. Fecha: 2026-11-08 (hoy)
3. Fecha: 2026-11-09 (mañana)

**Salida Esperada para (1) y (2):**
- Mensaje: "La fecha debe ser futura"
- Campo de fecha resaltado
- Botón guardar deshabilitado

**Salida Esperada para (3):**
- Aceptación de la fecha
- Botón guardar habilitado

**Criterio de Aceptación:**
- ✅ Fechas pasadas rechazadas
- ✅ Fecha de hoy rechazada
- ✅ Fecha futura aceptada
- ✅ Validación inmediata

**Estado de Verificación:** ☐ No verificado

---

#### REQ-07: Validación de Longitud de Entrada
**Funcionalidad:** Validar límites mínimos y máximos en campos de texto  
**Campo: Razón de la consulta (10-500 caracteres)**
- Entrada: "A" (1 carácter)
  - Esperado: Rechazo, mensaje "Mínimo 10 caracteres"
- Entrada: "Dolor leve de cabeza" (19 caracteres)
  - Esperado: Aceptación
- Entrada: (500+ caracteres)
  - Esperado: Rechazo, mensaje "Máximo 500 caracteres"

**Criterio de Aceptación:**
- ✅ Rechaza entradas menores a 10 caracteres
- ✅ Rechaza entradas mayores a 500 caracteres
- ✅ Mensaje de error específico
- ✅ Campo editable para corregir

**Estado de Verificación:** ☐ No verificado

---

### PERSISTENCIA Y CONSISTENCIA (2 requisitos)

#### REQ-08: Persistencia de Datos tras Cierre de Sesión
**Funcionalidad:** Los registros creados persisten cuando el usuario cierra sesión y vuelve a iniciar  
**Procedimiento:**
1. Usuario A inicia sesión
2. Crea una cita "PRUEBA_PERSISTENCIA_001"
3. Confirma que aparece en su lista
4. Cierra la aplicación completamente
5. Abre la aplicación nuevamente
6. Inicia sesión nuevamente

**Salida Esperada:**
- La cita "PRUEBA_PERSISTENCIA_001" aparece en la lista
- Los datos son idénticos a los guardados
- Timestamp de creación es el mismo

**Criterio de Aceptación:**
- ✅ Cita existe en Firestore
- ✅ Datos completos y correctos
- ✅ ID de documento no cambió
- ✅ Carga automática sin acción del usuario

**Estado de Verificación:** ☐ No verificado

---

#### REQ-09: Consistencia de Datos Entre Sesiones
**Funcionalidad:** Los cambios realizados en una sesión son visibles cuando el usuario vuelve a iniciar sesión en otro dispositivo  
**Procedimiento:**
1. Usuario A crea cita desde Dispositivo 1
2. Cierra sesión en Dispositivo 1
3. Usuario A inicia sesión en Dispositivo 2 (emulador diferente)
4. Consulta su lista de citas

**Salida Esperada:**
- La cita creada en Dispositivo 1 aparece en Dispositivo 2
- Todos los campos son idénticos

**Criterio de Aceptación:**
- ✅ Datos sincronizados entre dispositivos
- ✅ Sin duplicados
- ✅ Carga en < 5 segundos
- ✅ Información completa

**Estado de Verificación:** ☐ No verificado

---

### NAVEGACIÓN, ROLES Y PERMISOS (2 requisitos)

#### REQ-10: Navegación según Rol de Usuario
**Funcionalidad:** El usuario admin ve opciones diferentes que el usuario regular  
**Usuario Regular:**
- ✅ Ver mi perfil
- ✅ Ver mis citas
- ✅ Ver mis registros médicos
- ✅ Ver mis contactos de emergencia
- ❌ No ve "Gestión de Usuarios"
- ❌ No ve "Panel de Admin"

**Usuario Admin:**
- ✅ Todas las opciones del usuario regular
- ✅ "Gestión de Usuarios"
- ✅ "Panel de Admin"
- ✅ "Auditoría de Cambios"

**Criterio de Aceptación:**
- ✅ Elementos visibles solo si el rol es correcto
- ✅ No se puede acceder a rutas admin sin ser admin
- ✅ Redirección automática si intenta acceder sin permisos

**Estado de Verificación:** ☐ No verificado

---

#### REQ-11: Aislamiento de Datos por Usuario
**Funcionalidad:** Un usuario solo puede ver sus propios datos  
**Procedimiento:**
1. Usuario A inicia sesión, crea cita CITA_A
2. Usuario B inicia sesión, crea cita CITA_B
3. Usuario A consulta su lista de citas
4. Usuario B consulta su lista de citas

**Salida Esperada:**
- Usuario A solo ve CITA_A
- Usuario B solo ve CITA_B
- Ninguno ve datos del otro usuario

**Criterio de Aceptación:**
- ✅ Filtrado por UID del usuario autenticado
- ✅ Bases de datos locales no mezclan datos
- ✅ Reglas de Firestore lo validan

**Estado de Verificación:** ☐ No verificado

---

### MANEJO DE ERRORES (1 requisito)

#### REQ-12: Manejo de Errores de Conexión
**Funcionalidad:** La app informa al usuario cuando hay pérdida de conectividad  
**Escenarios:**
1. Sin conexión a internet al intentar guardar cita
2. Conexión interrumpida durante la carga de lista
3. Servidor no responde (timeout)

**Salida Esperada:**
- Mensaje claro: "Error de conexión. Por favor, verifica tu internet"
- Opción de "Reintentar"
- Datos locales se conservan

**Criterio de Aceptación:**
- ✅ Mensaje visible y legible
- ✅ Usuario sabe qué paso (conexión, servidor, etc.)
- ✅ Opción de reintentar disponible
- ✅ No se muestra OK si falló la operación

**Estado de Verificación:** ☐ No verificado

---

## 3. MATRIZ DE PRUEBAS DE CAJA NEGRA

| ID | Requisito | Entrada | Salida Esperada | Resultado | Evidencia | Observaciones |
|---|---|---|---|---|---|---|
| REQ-01 | Crear cita | Dr. García, Cardiología, 2026-11-15 09:00, "Chequeo" | Confirmación, ID generado | ☐ | [Screenshot] | |
| REQ-02 | Editar perfil | Nombre: "Juan", Sangre: O+ | Confirmación, datos actualizados | ☐ | [Screenshot] | |
| REQ-03 | Filtrar citas | Inicio: 2026-11-01, Fin: 2026-11-30 | Lista filtrada, 0+ resultados | ☐ | [Screenshot] | |
| REQ-04 | Eliminar registro | ID: REC123, Confirmar SÍ | "Registro eliminado", no aparece en lista | ☐ | [Screenshot] | |
| REQ-05 | Teléfono inválido | "12345" | Error, campo resaltado | ☐ | [Screenshot] | |
| REQ-06 | Fecha pasada | 2026-11-08 | Error, "fecha futura requerida" | ☐ | [Screenshot] | |
| REQ-07 | Texto muy corto | "A" | Error, "mínimo 10 caracteres" | ☐ | [Screenshot] | |
| REQ-08 | Persistencia | Crear, cerrar app, reabrir | Datos persisten | ☐ | [Screenshot] | |
| REQ-09 | Sincronización | Crear en Dev1, abrir en Dev2 | Datos visibles en Dev2 | ☐ | [Screenshot] | |
| REQ-10 | Permisos rol | Admin vs Usuario | Menús diferentes | ☐ | [Screenshot] | |
| REQ-11 | Aislamiento datos | Usuario A vs Usuario B | Datos separados | ☐ | [Screenshot] | |
| REQ-12 | Error conexión | Sin wifi, intentar guardar | Mensaje de error, opción reintentar | ☐ | [Screenshot] | |

---

## 4. DEFECTOS ENCONTRADOS

### Defecto 1: [ID_DEFECTO]
**Descripción:** [Descripción del defecto]  
**Paso para reproducir:** [Pasos detallados]  
**Resultado observado:** [Lo que sucedió]  
**Resultado esperado:** [Lo que debería pasar]  
**Severidad:** [Crítica | Alta | Media | Baja]  
**Estado:** [Abierto | En revisión | Cerrado]  

---

## 5. CONCLUSIÓN

### Resumen de Resultados
- Total de requisitos: 12
- Verificados: 0/12
- Defectos encontrados: 0
- Tasade éxito: 0%

### Recomendación
🔴 [Producto listo para liberar | Necesita correcciones | No apto para liberar]

**Justificación:** [Explicar brevemente si la app cumple con los requisitos mínimos de calidad]

---

## EVIDENCIAS

### Capturas de Pantalla
- [ ] Pantalla de inicio de sesión
- [ ] Pantalla de creación de cita
- [ ] Pantalla de perfil de usuario
- [ ] Pantalla de lista de citas
- [ ] Mensaje de error de validación
- [ ] Pantalla de admin (solo para admin)

### Documentos de Firestore
- [ ] Usuario de prueba A
- [ ] Usuario de prueba B
- [ ] Cita creada desde dispositivo A
- [ ] Cita creada desde dispositivo B

---

## NOTAS DEL EVALUADOR

[Espacio para notas adicionales, observaciones y recomendaciones]
