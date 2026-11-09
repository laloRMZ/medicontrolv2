# PRÁCTICA 9: Conexiones y Pruebas de Base de Datos entre Dispositivos
## MediControl V2 - Sincronización de Datos en Firestore

**Proyecto:** MediControl V2  
**Tema:** Validar conectividad, persistencia y sincronización de datos médicos entre dos dispositivos (smartphones/emuladores)  
**Fecha:** Noviembre 2026  
**Requisito:** Dos dispositivos Android con la misma app conectados al mismo proyecto Firebase  

---

## OBJETIVO

Comprobar que:
1. Ambos dispositivos se conectan a la misma base de datos Firestore
2. Los cambios realizados en un dispositivo se propagan al otro
3. La información es consistente entre dispositivos
4. Se manejan correctamente los conflictos de actualización simultánea
5. Los datos persisten después de cerrar la aplicación

---

## FASE 1: VERIFICACIÓN DE CONECTIVIDAD

### Paso 1.1: Configurar dispositivos
**Acción:**
- [ ] Dispositivo A: Smartphone 1 (o Emulador Android Studio)
- [ ] Dispositivo B: Smartphone 2 (o Emulador diferente)
- [ ] Ambos con la última versión de MediControl V2 instalada
- [ ] Ambos conectados a la misma red WiFi

### Paso 1.2: Verificar proyecto Firebase
**En Firebase Console:**
- [ ] Proyecto: medicontrolv2
- [ ] Base de datos Firestore activa
- [ ] Colecciones visibles: 
  - [ ] users
  - [ ] appointments
  - [ ] medicalRecords
  - [ ] emergencyContacts
  - [ ] doctors

### Paso 1.3: Iniciar sesión en ambos dispositivos
**Dispositivo A:**
- Usuario: usuario.a@medicontrol.test
- Contraseña: [Contraseña temporal]
- [ ] Sesión iniciada correctamente
- [ ] UID visible: `[____________]`

**Dispositivo B:**
- Usuario: usuario.b@medicontrol.test
- Contraseña: [Contraseña temporal]
- [ ] Sesión iniciada correctamente
- [ ] UID visible: `[____________]`

### Paso 1.4: Verificar acceso a funciones principales
**Dispositivo A:**
- [ ] Pantalla de citas accesible
- [ ] Botón "Nueva cita" visible
- [ ] Lista de citas vacía o con datos existentes

**Dispositivo B:**
- [ ] Pantalla de citas accesible
- [ ] Botón "Nueva cita" visible
- [ ] Lista de citas vacía o con datos existentes

**Estado inicial de Firestore:**
```
Colección 'appointments':
Total de documentos: [____]
Documentos de usuario A: [____]
Documentos de usuario B: [____]
Timestamp de última actualización: [____________]
```

---

## FASE 2: PRUEBA DE ESCRITURA Y LECTURA CRUZADA

### Prueba DB-01: Conexión compartida
**Esperado:** Ambos dispositivos acceden al mismo proyecto y colección  
**Procedimiento:**
1. En Firebase Console, anota el ID del proyecto
2. En Dispositivo A, accede a Configuración > Sobre la app
3. Verifica que el ID de Firebase sea `medicontrolv2`
4. Repite en Dispositivo B

**Resultado esperado:** Ambos muestran el mismo ID de proyecto  
**Resultado observado:** `[________________]`  
**Observación:** `[________________]`

---

### Prueba DB-02: Escritura desde Dispositivo A
**Esperado:** La cita creada por A aparece en Firestore  

**Procedimiento:**
```
Dispositivo A:
1. Abre la app y ve "Mis citas"
2. Toca "Nueva cita"
3. Completa:
   - Doctor: García Rodríguez
   - Especialidad: Cardiología
   - Fecha: 2026-11-15
   - Hora: 09:00
   - Razón: PRUEBA_DB02_ESCRITURA_A
4. Toca "Guardar cita"
5. Espera confirmación visual
6. Anota la hora local: [__:__]
```

**Validación en Firestore:**
```
Colección: appointments
Documento ID: [____________]
Campo: userId = [UID de A]
Campo: reason = "PRUEBA_DB02_ESCRITURA_A"
Campo: doctor = "García Rodríguez"
Timestamp de creación: [____________]
```

**Resultado esperado:** ✅ Documento existe en Firestore  
**Resultado observado:** ☐ Encontrado | ☐ No encontrado  
**Observación:** `[________________]`

---

### Prueba DB-03: Lectura desde Dispositivo B
**Esperado:** B puede recuperar la cita creada por A  

**Procedimiento:**
```
Dispositivo B:
1. Abre "Mis citas"
2. Si la lista aparece vacía, toca "Actualizar" o espera 5 segundos
3. Busca una cita con razón "PRUEBA_DB02_ESCRITURA_A"
4. Anota si aparece: ☐ Inmediatamente | ☐ Después de actualizar | ☐ No aparece
5. Tiempo total de propagación: [__:__] segundos
```

**Validación:**
- [ ] La cita aparece en Dispositivo B
- [ ] El doctor es "García Rodríguez"
- [ ] La fecha y hora son correctas
- [ ] El estado es "Pendiente"

**Resultado esperado:** ✅ Cita visible en Dispositivo B dentro de 5 segundos  
**Resultado observado:** ☐ Visible inmediatamente | ☐ Visible después de actualizar | ☐ No visible  
**Tiempo de propagación:** `[____] segundos`  
**Observación:** `[________________]`

---

### Prueba DB-04: Escritura desde Dispositivo B
**Esperado:** La cita creada por B se almacena correctamente  

**Procedimiento:**
```
Dispositivo B:
1. Abre "Nueva cita"
2. Completa:
   - Doctor: López Martínez
   - Especialidad: Neumología
   - Fecha: 2026-11-16
   - Hora: 14:00
   - Razón: PRUEBA_DB04_ESCRITURA_B
3. Guarda cita
4. Espera confirmación
5. Anota la hora: [__:__]
```

**Validación en Firestore:**
- [ ] Documento creado con ID único
- [ ] Campo userId = UID de B
- [ ] Campo reason = "PRUEBA_DB04_ESCRITURA_B"
- [ ] Timestamp registrado correctamente

**Resultado esperado:** ✅ Documento en Firestore  
**Resultado observado:** ☐ Encontrado | ☐ No encontrado  
**Observación:** `[________________]`

---

### Prueba DB-05: Lectura desde Dispositivo A
**Esperado:** A puede recuperar la cita creada por B  

**Procedimiento:**
```
Dispositivo A:
1. Abre "Mis citas"
2. Busca cita con razón "PRUEBA_DB04_ESCRITURA_B"
3. ¿Aparece?: ☐ Sí | ☐ No
4. Si no aparece, toca "Actualizar"
5. Tiempo de propagación: [____] segundos
```

**Validación:**
- [ ] La cita del doctor López Martínez aparece
- [ ] La especialidad es Neumología
- [ ] La fecha y hora son 2026-11-16 14:00
- [ ] El estado es "Pendiente"

**Resultado esperado:** ✅ Cita visible en Dispositivo A  
**Resultado observado:** ☐ Visible inmediatamente | ☐ Visible después de actualizar | ☐ No visible  
**Tiempo de propagación:** `[____] segundos`  
**Observación:** `[________________]`

---

## FASE 3: ACTUALIZACIÓN Y SINCRONIZACIÓN

### Prueba DB-06: Actualización cruzada con propagación
**Esperado:** El cambio confirmado es visible en el otro dispositivo  

**Procedimiento:**
```
Dispositivo A:
1. Localiza la cita PRUEBA_DB02_ESCRITURA_A (la que creaste)
2. Toca la cita para abrirla
3. Toca "Editar"
4. Cambia el Estado de "Pendiente" a "En Proceso"
5. Anota la hora de cambio: [__:__]
6. Toca "Guardar"
7. Espera confirmación visual: [Confirmación recibida a las __:__]
```

**En Dispositivo B (simultáneamente o después):**
```
1. Abre "Mis citas"
2. Busca la misma cita PRUEBA_DB02_ESCRITURA_A
   - NOTA: Este usuario NO es propietario de la cita
   - ¿Debería verla?: [Según reglas de seguridad]
3. Si es visible, ¿muestra el nuevo estado "En Proceso"?: ☐ Sí | ☐ No
4. Tiempo para actualización: [____] segundos
```

**Validación en Firestore:**
```
Documento de la cita:
- status (o estado): "En Proceso"
- lastModified: [Timestamp del cambio]
- modifiedBy: [UID de A]
```

**Resultado esperado:**
- ✅ Firestore muestra estado "En Proceso"
- ✅ Si la aplicación permite ver citas de otros (basado en reglas), se actualiza
- ✅ O si no lo permite, B no debería verla (validar según diseño)

**Resultado observado:** ☐ Se actualizó | ☐ No se actualizó | ☐ No es visible para B  
**Tiempo de propagación:** `[____] segundos`  
**Observación:** `[________________]`

---

### Prueba DB-06b: Cambio de campos múltiples
**Procedimiento:**
```
Dispositivo B:
1. Si tienes acceso a cita PRUEBA_DB04_ESCRITURA_B (que creaste):
2. Edita:
   - Fecha: Cambia a 2026-11-20
   - Hora: Cambia a 10:00
   - Razón: Agrega " [MODIFICADO_B]"
3. Guarda
4. Hora de cambio: [__:__]
```

**En Dispositivo A:**
```
1. Abre la cita PRUEBA_DB04_ESCRITURA_B
2. ¿Se actualiza la fecha?: ☐ Sí | ☐ No
3. ¿Se actualiza la hora?: ☐ Sí | ☐ No
4. ¿Se actualiza la razón?: ☐ Sí | ☐ No
5. Tiempo de propagación: [____] segundos
```

**Resultado observado:**
- Cambios propagados: `[ ] / [ ] / [ ]` (x de 3)
- Tiempo máximo: `[____]` segundos

---

## FASE 4: PRUEBA DE CONFLICTOS

### Prueba DB-07: Modificación concurrente del mismo registro
**Esperado:** El resultado final cumple la política de actualización definida  

**Prerequisito:**
- Ambos dispositivos tienen abierta la misma cita (misma pantalla, mismo documento)

**Procedimiento:**
```
Prepare una cita compartida (o cree una):
Dispositivo A y B: Abre la cita "PRUEBA_CONFLICTO"

Sincronización de tiempo (importante):
1. Anota hora actual: [__:__]
2. Countdown: 3...2...1... YA!

Dispositivo A (en el segundo 0):
1. Toca "Editar"
2. Cambia Estado a "En Proceso"
3. ESPERA (no guardes aún, si la app lo permite)
4. Anota: ¿Puede editar sin guardar?: ☐ Sí | ☐ No

Dispositivo B (en el segundo 2):
1. Toca "Editar"
2. Cambia Prioridad a "Alta" (si aplica)
3. Guarda inmediatamente
4. Anota confirmación y hora: [__:__]

Dispositivo A:
1. Guarda el cambio de Estado
2. Anota confirmación y hora: [__:__]
3. ¿Mostró error?: ☐ Sí | ☐ No
4. Si hay error, anota: [________________]
```

**Verificación en ambos dispositivos:**
```
Dispositivo A: ¿Qué valores ve?
- Estado: [____________]
- Prioridad: [____________]
- Hora de verificación: [__:__]

Dispositivo B: ¿Qué valores ve?
- Estado: [____________]
- Prioridad: [____________]
- Hora de verificación: [__:__]
```

**Validación en Firestore:**
```
Documento final:
- status (Estado): [____________]
- priority (Prioridad): [____________]
- lastModified: [____________]
- conflictResolution (si está registrado): [____________]
```

**Análisis:**
- ✅ ¿Ambos dispositivos ven los mismos valores?
- ✅ ¿Qué política se aplicó? (Last-write-wins | Merge | Error)
- ✅ ¿Se perdió algún dato?

**Resultado esperado:** La política está claramente definida (Last-write-wins por defecto en Firestore)  
**Resultado observado:** 
```
Política aplicada: [ ] LWW | [ ] Merge | [ ] Error
Datos perdidos: ☐ No | ☐ Sí (Estado A se perdió | Prioridad B se perdió | Ambos)
Consistencia: ☐ Consistente | ☐ Inconsistente
```
**Observación:** `[________________]`

---

## FASE 5: PRUEBA DE PERSISTENCIA

### Prueba DB-08: Persistencia tras cerrar y abrir la app
**Esperado:** Los registros confirmados permanecen tras cerrar y abrir la app  

**Procedimiento Dispositivo A:**
```
1. Crea una cita nueva: "PRUEBA_PERSISTENCIA_001"
   - Doctor: Dr. Test
   - Especialidad: Medicina General
   - Fecha: 2026-11-18
   - Hora: 11:00
2. Guarda y ve confirmación
3. Anota hora de creación: [__:__]
4. Cierra completamente la aplicación:
   - Desliza hacia arriba (Android)
   - Fuerza detención desde Configuración
   - O cierra el emulador
5. Espera 10 segundos
6. Reabre la aplicación
7. Inicia sesión nuevamente (si es necesario)
8. Abre "Mis citas"
9. Busca "PRUEBA_PERSISTENCIA_001"
```

**Validación:**
- [ ] La cita aparece en la lista
- [ ] El doctor es "Dr. Test"
- [ ] La fecha y hora son correctas
- [ ] Todos los campos coinciden con los guardados

**Tiempo de carga:** `[__:__]` segundos desde que abre la app  
**Estado en Firestore:** ☐ Presente | ☐ Ausente | ☐ Parcial

**Resultado esperado:** ✅ Cita persiste y es totalmente recuperable  
**Resultado observado:** ☐ Persiste | ☐ No persiste | ☐ Persiste parcialmente  
**Observación:** `[________________]`

---

### Prueba DB-08b: Sincronización de persistencia
**Procedimiento Dispositivo B:**
```
1. Cierra completamente MediControl
2. Espera 5 segundos
3. Reabre la aplicación
4. Inicia sesión
5. Abre "Mis citas"
6. Busca "PRUEBA_DB04_ESCRITURA_B" (cita que creaste en Fase 2)
7. ¿Aparece?: ☐ Sí | ☐ No
8. Busca "PRUEBA_PERSISTENCIA_001" (cita creada por A)
   - ¿Debería verla?: Según reglas de datos
   - ¿La ve?: ☐ Sí | ☐ No
```

**Resultado esperado:**
- ✅ Las propias citas de B persisten
- ✅ No ve citas privadas de A (si hay aislamie de datos)

**Resultado observado:** 
- Citas propias persistentes: ☐ Sí | ☐ No | ☐ Parcial
- Datos privados de A visibles: ☐ Sí | ☐ No

---

## FASE 6: MANEJO DE ERRORES E INTERRUPCIONES

### Prueba DB-09: Pérdida de conexión
**Esperado:** La aplicación informa o gestiona la operación sin confirmar falsamente el éxito  

**Procedimiento:**
```
Dispositivo A (conectado a WiFi):
1. Intenta crear una cita
2. MIENTRAS escribe o después de tocar "Guardar":
   - Desactiva WiFi
   - O desactiva móvil datos
   - Anota hora: [__:__]
3. ¿Qué sucede?:
   ☐ La app muestra error inmediatamente
   ☐ La app espera un timeout (¿cuánto tiempo?)
   ☐ La app guarda localmente y sincroniza después
   ☐ La app muestra un spinner indefinido

4. Reactiva la conexión
5. ¿Se recupera?: ☐ Sí | ☐ No
6. ¿El documento se guardó?: ☐ Sí | ☐ No
```

**Validación en Firestore:**
- Documento creado pero sin UID de propietario (error)
- Documento incompleto (falta de campos obligatorios)
- Documento completo y correcto
- Sin documento (operación rechazada correctamente)

**Resultado esperado:** 
- ✅ Si se guarda, debe ser completo y válido
- ✅ Si falla, se debe mostrar un error claro
- ✅ No "confirmación falsa"

**Resultado observado:**
```
Manejo de error: [ ] Correcto | [ ] Incorrecto
Documento en Firestore: [ ] Completo | [ ] Incompleto | [ ] Ausente
Mensaje al usuario: "[________________]"
Se puede reintentar: [ ] Sí | [ ] No
```

**Observación:** `[________________]`

---

## MATRIZ DE PRUEBAS DB

| ID | Prueba | Acción | Esperado | Resultado | Observaciones |
|---|---|---|---|---|---|
| DB-01 | Conexión compartida | Verificar ID proyecto en ambos | Mismo ID en A y B | ☐ Pasó | |
| DB-02 | Escritura desde A | Crear cita PRUEBA_DB02 | Aparece en Firestore | ☐ Pasó | |
| DB-03 | Lectura desde B | Buscar cita PRUEBA_DB02 | Aparece en B | ☐ Pasó | |
| DB-04 | Escritura desde B | Crear cita PRUEBA_DB04 | Aparece en Firestore | ☐ Pasó | |
| DB-05 | Lectura desde A | Buscar cita PRUEBA_DB04 | Aparece en A | ☐ Pasó | |
| DB-06 | Actualización cruzada | A cambia estado | B ve actualización | ☐ Pasó | |
| DB-07 | Conflicto concurrente | A y B modifican simultáneamente | Policy LWW aplicada | ☐ Pasó | |
| DB-08 | Persistencia | Cerrar app y reabre | Datos persisten | ☐ Pasó | |
| DB-09 | Pérdida conexión | Sin internet + guardar | Error informado, sin falsa confirmación | ☐ Pasó | |

---

## ANÁLISIS Y CONCLUSIONES

### Defectos Detectados
1. **Defecto [ID]:** [Descripción]
   - Severidad: [ ] Crítica | [ ] Alta | [ ] Media | [ ] Baja
   - Afecta a: Sincronización / Persistencia / Conflictos
   - Reproducer: [Pasos]
   - Estado: [ ] Abierto | [ ] Cerrado

### Riegos de Sincronización Identificados
- [ ] La app no actualiza automáticamente cuando otros usuarios modifican datos
- [ ] No hay manejo de conflictos de edición concurrente
- [ ] Los datos no sincronizados se pierden al cambiar de dispositivo
- [ ] No se valida la pérdida de conexión durante transacciones
- [ ] No hay indicador visual de sincronización en progreso

### Recomendaciones
1. Implementar listener en tiempo real (`.listen()` en Firestore)
2. Mostrar indicador visual de sincronización
3. Definir y documentar política de resolución de conflictos
4. Añadir reintentos automáticos tras pérdida de conexión
5. Validar integridad de documentos tras recuperación

### Resultado Final
**Apto para liberar:** ☐ Sí | ☐ No | ☐ Con condiciones

**Justificación:** [Resumen ejecutivo]

---

## EVIDENCIAS FOTOGRÁFICAS

- [ ] Captura: Firebase Console mostrando ambos usuarios
- [ ] Captura: Dispositivo A lista de citas vacía antes de pruebas
- [ ] Captura: Dispositivo B lista de citas vacía antes de pruebas
- [ ] Captura: Dispositivo A cita creada exitosamente
- [ ] Captura: Firestore mostrando documento creado
- [ ] Captura: Dispositivo B viendo la cita de A
- [ ] Captura: Dispositivo A viendo actualización de B
- [ ] Captura: Mensajes de error en conexión perdida
- [ ] Video: Sincronización en tiempo real (opcional)

