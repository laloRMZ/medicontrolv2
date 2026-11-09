# PRÁCTICA 10: Seguridad, Autenticación y Control de Acceso
## MediControl V2 - Validación de Controles de Seguridad en Base de Datos Compartida

**Proyecto:** MediControl V2  
**Tema:** Implementar y validar que cada usuario solamente realice operaciones autorizadas sobre datos en Firebase  
**Fecha:** Noviembre 2026  
**Requisito:** Dos dispositivos con autenticación y reglas de Firestore configuradas  

---

## OBJETIVO

Comprobar que:
1. La autenticación funciona correctamente
2. Cada usuario se identifica de manera única (UID)
3. Los datos están asociados al usuario propietario
4. Las reglas de Firestore cumplen la política de acceso
5. No se puede acceder a datos ajenos manipulando la aplicación o cliente
6. Los cambios no autorizados son rechazados por el servidor

---

## FASE 1: CONFIGURACIÓN DE AUTENTICACIÓN

### Paso 1.1: Habilitar Autenticación en Firebase
**En Firebase Console:**
1. [ ] Authentication > Sign-in method
2. [ ] Habilitar: Email/Contraseña
3. [ ] Guardar configuración

### Paso 1.2: Crear dos cuentas de prueba

**Usuario A:**
```
Email: usuario.a@medicontrol.test
Contraseña: TestPass123!
Nombre: Usuario A
Rol: Usuario Regular
Fecha creación: [____________]
UID Auto-generado: [________________________]
```

**Usuario B:**
```
Email: usuario.b@medicontrol.test
Contraseña: TestPass456!
Nombre: Usuario B
Rol: Usuario Regular
Fecha creación: [____________]
UID Auto-generado: [________________________]
```

### Paso 1.3: Verificar UIDs únicos
**En Firestore, colección 'users':**
```
Documento de A:
- uid: [________________________]
- email: usuario.a@medicontrol.test
- name: Usuario A

Documento de B:
- uid: [________________________]
- email: usuario.b@medicontrol.test
- name: Usuario B
```

**Verificación:**
- [ ] UIDs son diferentes
- [ ] UIDs coinciden con Firebase Authentication
- [ ] Cada usuario tiene un documento único

### Paso 1.4: Iniciar sesión en ambos dispositivos
**Dispositivo A:**
```
1. Abre MediControl
2. Pantalla Login > Ingresa usuario.a@medicontrol.test
3. Contraseña: TestPass123!
4. Toca "Inicia sesión"
5. Espera confirmación: [Tiempo de espera: __:__]
6. ¿Sesión iniciada?: ☐ Sí | ☐ No
```

**Verificación en App (si hay pantalla de perfil o debug):**
```
Dispositivo A muestra:
- Usuario autenticado: [ ] Sí | [ ] No
- Email: usuario.a@medicontrol.test
- UID visible (si la app lo muestra): [________________________]
```

**Dispositivo B:**
```
1. Abre MediControl
2. Pantalla Login > Ingresa usuario.b@medicontrol.test
3. Contraseña: TestPass456!
4. Toca "Inicia sesión"
5. Espera confirmación: [Tiempo de espera: __:__]
6. ¿Sesión iniciada?: ☐ Sí | ☐ No
```

**Verificación en App:**
```
Dispositivo B muestra:
- Usuario autenticado: [ ] Sí | [ ] No
- Email: usuario.b@medicontrol.test
- UID visible (si la app lo muestra): [________________________]
```

**Resultado esperado:**
- ✅ Ambos dispositivos muestran autenticación exitosa
- ✅ UIDs visibles son diferentes
- ✅ Cada usuario solo ve su propia sesión

**Resultado observado:**
- Sesión A: ☐ Exitosa | ☐ Fallida
- Sesión B: ☐ Exitosa | ☐ Fallida
- UIDs diferentes: ☐ Sí | ☐ No

---

## FASE 2: ASOCIACIÓN DE REGISTROS CON USUARIOS

### Paso 2.1: Crear citas con identificación de propietario
**Dispositivo A:**
```
1. Abre "Mis citas"
2. Toca "Nueva cita"
3. Completa:
   - Doctor: Cardiología Dr. García
   - Especialidad: Cardiología
   - Fecha: 2026-11-15
   - Hora: 09:00
   - Razón: CITA_SEGURIDAD_A_001
4. Toca "Guardar cita"
5. Hora de creación: [__:__]
```

**Validación en Firestore:**
```
Colección 'appointments'
Documento creado:
- appointmentId: [________________________]
- userId: [UID DE A - debe coincidir]
- creadoPor: [UID DE A]
- doctor: "Cardiología Dr. García"
- reason: "CITA_SEGURIDAD_A_001"
- timestamp: [____________]
- status: "Pendiente"
```

**Verificación:**
- [ ] Campo 'userId' = UID de A
- [ ] Campo 'creadoPor' = UID de A
- [ ] No hay campos con UID de B
- [ ] Timestamp es reciente

**Dispositivo B:**
```
1. Abre "Mis citas"
2. Toca "Nueva cita"
3. Completa:
   - Doctor: Neumología Dr. López
   - Especialidad: Neumología
   - Fecha: 2026-11-16
   - Hora: 14:00
   - Razón: CITA_SEGURIDAD_B_001
4. Toca "Guardar cita"
5. Hora de creación: [__:__]
```

**Validación en Firestore:**
```
Documento creado:
- appointmentId: [________________________]
- userId: [UID DE B - debe coincidir]
- creadoPor: [UID DE B]
- doctor: "Neumología Dr. López"
- reason: "CITA_SEGURIDAD_B_001"
- timestamp: [____________]
```

**Verificación:**
- [ ] Campo 'userId' = UID de B
- [ ] Campo 'creadoPor' = UID de B
- [ ] No hay UID de A
- [ ] Timestamp diferente a cita A

**Resultado observado:**
- Cita A tiene userId de A: ☐ Sí | ☐ No
- Cita B tiene userId de B: ☐ Sí | ☐ No
- Propietarios correctamente asignados: ☐ Sí | ☐ No

---

## FASE 3: IMPLEMENTACIÓN DE REGLAS DE SEGURIDAD

### Paso 3.1: Configurar reglas de Firestore
**En Firebase Console > Firestore > Reglas:**

**Regla propuesta (copiar a Firestore Rules):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios solo pueden leer y escribir sus propios documentos
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == request.resource.data.uid;
      allow update: if request.auth.uid == userId
                       && resource.data.uid == request.resource.data.uid;
      allow delete: if request.auth.uid == userId;
    }
    
    // Citas: Usuario solo accede a sus propias citas
    match /appointments/{appointmentId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId
                       && request.auth.uid == request.resource.data.creadoPor;
      allow update: if request.auth.uid == resource.data.userId
                       && resource.data.userId == request.resource.data.userId;
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // Registros médicos: Solo el propietario
    match /medicalRecords/{recordId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update: if request.auth.uid == resource.data.userId;
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // Contactos de emergencia: Solo el propietario
    match /emergencyContacts/{contactId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update: if request.auth.uid == resource.data.userId;
      allow delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

**Pasos:**
1. [ ] Copiar reglas en editor de Firestore
2. [ ] Revisar sintaxis (debe estar verde)
3. [ ] Toca "Publicar"
4. [ ] Espera confirmación: [Reglas publicadas a las __:__]

### Paso 3.2: Verificar reglas activas
**En Firestore Console:**
- [ ] Estado: "Reglas publicadas"
- [ ] Fecha de última actualización: [____________]
- [ ] Sin errores de sintaxis

---

## FASE 4: PRUEBAS DE ACCESO AUTORIZADO Y NO AUTORIZADO

### Prueba SEG-01: Inicio de sesión válido
**Acción:** Ingresar con la cuenta del usuario A  
**Esperado:** Autenticación exitosa

**Procedimiento:**
```
Pantalla Login:
Email: usuario.a@medicontrol.test
Contraseña: TestPass123!
Toca: "Inicia sesión"
```

**Validación:**
- [ ] Botón deshabilitado mientras procesa
- [ ] Spinner de carga visible
- [ ] Redirección a home/dashboard
- [ ] Tiempo de autenticación: [__:__] segundos

**Resultado esperado:** ✅ Pantalla principal accesible  
**Resultado observado:** ☐ Pasó | ☐ Falló  
**Evidencia:** [Captura de pantalla]

---

### Prueba SEG-02: Inicio de sesión inválido
**Acción:** Intentar ingresar con contraseña incorrecta  
**Esperado:** Acceso rechazado

**Procedimiento:**
```
Pantalla Login:
Email: usuario.a@medicontrol.test
Contraseña: ContraseñaIncorrecta123
Toca: "Inicia sesión"
```

**Validación:**
- [ ] Mensaje de error visible
- [ ] Usuario NO entra a la app
- [ ] Campo de contraseña se limpia (opcional pero seguro)
- [ ] Mensaje específico: "Contraseña incorrecta" o genérico "Credenciales inválidas"

**Mensaje observado:** `[________________]`

**Resultado esperado:** ✅ Acceso rechazado con error claro  
**Resultado observado:** ☐ Pasó | ☐ Falló  
**Observación:** `[________________]`

---

### Prueba SEG-03: Creación propia - A registra una cita
**Acción:** A registra una cita con su UID  
**Esperado:** Documento creado con propietario A

**Procedimiento:**
```
Dispositivo A (autenticado como usuario.a@medicontrol.test):
1. Abre "Mis citas"
2. Toca "Nueva cita"
3. Completa:
   - Doctor: Test Dr.
   - Especialidad: Prueba
   - Fecha: 2026-11-20
   - Hora: 15:00
   - Razón: CITA_CREACION_PROPIA
4. Guarda
```

**Validación en Firestore:**
```
Documento creado:
- userId: [UID de A]
- creadoPor: [UID de A]
- Acceso de A: ☐ Lectura ✓ | ☐ Lectura ✗
```

**Resultado esperado:**
- ✅ Documento existe
- ✅ userId = UID de A
- ✅ A puede leer su propia cita

**Resultado observado:** ☐ Pasó | ☐ Falló  
**Evidencia:** `[Documento ID: ________________]`

---

### Prueba SEG-04: Suplantación de propietario - A intenta asignar UID de B
**Acción:** A intenta crear una cita pero especifica el UID de B como propietario  
**Esperado:** Firestore rechaza la escritura

**Procedimiento:**
```
Dispositivo A:
ESCENARIO 1: Si la app no permite editar el campo 'userId':
- La app automáticamente asigna el UID de A
- Resultado esperado: userId = A (seguro)

ESCENARIO 2: Si la app permite editar directamente 'userId':
1. Intenta crear documento con:
   {
     "userId": "[UID_DE_B]",
     "creadoPor": "[UID_DE_A]",
     "reason": "PRUEBA_SUPLANTACION"
   }
2. Guarda

Validación en Firestore:
- ¿El documento se creó?: ☐ Sí | ☐ No
- Si SÍ: userId tiene valor [____________]
- ¿Coincide con A?: ☐ Sí | ☐ No
```

**Resultado esperado:**
- ✅ La regla rechaza si userId != auth.uid
- ✅ Error en cliente (si hay validación previa)
- ✅ Documento NO se crea en Firestore

**Resultado observado:**
- Intento de escritura: ☐ Permitido | ☐ Rechazado
- Documento creado: ☐ Sí | ☐ No
- Error recibido: `[________________]`

**Severidad si falló:** ☐ Crítica | ☐ Alta

---

### Prueba SEG-05: Lectura de datos ajenos - A intenta leer cita de B
**Acción:** A intenta leer directamente una cita creada por B  
**Esperado:** Lectura denegada

**Procedimiento:**
```
Requisitos previos:
- Documento de cita de B existe: CITA_SEGURIDAD_B_001
- Documento ID conocido: [________________________]
- Dispositivo A autenticado como A

Ejecución:
1. En pantalla de lista de citas:
   - ¿Aparece la cita CITA_SEGURIDAD_B_001?: ☐ Sí | ☐ No
   
2. Si aparece:
   - Toca para abrir detalles
   - ¿Se abre?: ☐ Sí | ☐ No
   
3. Si NO aparece en lista:
   - Verifica en Firestore Console
   - Cita existe: ☐ Sí | ☐ No
   - Propietario: [UID de B]

4. Intenta acceso técnico (si es posible):
   - Abre consola/debugger
   - Ejecuta: db.collection('appointments').doc('[ID_CITA_B]').get()
   - ¿Retorna datos?: ☐ Sí (ERROR) | ☐ No (Correcto)
   - Error recibido: `[________________]`
```

**Resultado esperado:**
- ✅ Cita de B NO aparece en lista de A
- ✅ Firestore rechaza lectura directa
- ✅ Mensaje de error: "Permission denied"

**Resultado observado:**
- Cita visible en lista: ☐ Sí (FALLO) | ☐ No (Pasó)
- Acceso técnico bloqueado: ☐ Sí (Pasó) | ☐ No (FALLO)
- Error: `[________________]`

**Severidad si falló:** ☐ Crítica

---

### Prueba SEG-06: Actualización de datos ajenos - A intenta modificar cita de B
**Acción:** A intenta modificar una cita de B  
**Esperado:** Actualización denegada

**Procedimiento:**
```
Dispositivo A:
1. Localiza cita CITA_SEGURIDAD_B_001 (si es visible)
2. Si es visible, toca para abrir
3. Toca "Editar"
4. Cambia el estado de la cita
5. Toca "Guardar"

Resultado observado:
- ¿Se abre para editar?: ☐ Sí | ☐ No
- ¿Se permite guardar?: ☐ Sí | ☐ No
- Mensaje de error: `[________________]`

Validación técnica:
- Intenta ejecutar update en Firestore:
  db.collection('appointments').doc('[ID_CITA_B]').update({
    status: 'En Proceso'
  })
- ¿Se actualiza?: ☐ Sí (ERROR) | ☐ No (Correcto)
- Error recibido: `[________________]`
```

**Resultado esperado:**
- ✅ Botón de editar no aparece o está deshabilitado
- ✅ Firestore rechaza la actualización
- ✅ Error: "Permission denied"

**Resultado observado:**
- Edición permitida: ☐ Sí (FALLO) | ☐ No (Pasó)
- Actualización bloqueada: ☐ Sí (Pasó) | ☐ No (FALLO)
- Error: `[________________]`

**Severidad si falló:** ☐ Crítica

---

### Prueba SEG-07: Eliminación de datos ajenos - A intenta eliminar cita de B
**Acción:** A intenta eliminar una cita de B  
**Esperado:** Eliminación denegada

**Procedimiento:**
```
Dispositivo A:
1. Localiza cita CITA_SEGURIDAD_B_001
2. Si es visible, busca opción "Eliminar"
3. Si hay opción, toca
4. Confirma eliminación si hay diálogo

Resultado observado:
- ¿Aparece botón eliminar?: ☐ Sí | ☐ No
- ¿Se permite confirmar?: ☐ Sí | ☐ No
- Mensaje: `[________________]`

Validación técnica:
- Intenta ejecutar delete:
  db.collection('appointments').doc('[ID_CITA_B]').delete()
- ¿Se elimina?: ☐ Sí (ERROR) | ☐ No (Correcto)
- Error recibido: `[________________]`

Verificación en Firestore:
- ¿Documento aún existe?: ☐ Sí (Correcto) | ☐ No (ERROR)
```

**Resultado esperado:**
- ✅ Botón de eliminar no aparece o está deshabilitado
- ✅ Firestore rechaza la eliminación
- ✅ Documento persiste en Firestore

**Resultado observado:**
- Eliminación permitida: ☐ Sí (FALLO) | ☐ No (Pasó)
- Documento persiste: ☐ Sí (Pasó) | ☐ No (FALLO)

**Severidad si falló:** ☐ Crítica

---

### Prueba SEG-08: Actualización propia - A modifica el estado de su cita
**Acción:** A modifica el estado de su propia cita  
**Esperado:** Actualización permitida

**Procedimiento:**
```
Dispositivo A:
1. Abre la cita CITA_SEGURIDAD_A_001 (creada por A)
2. Toca "Editar"
3. Cambia Estado de "Pendiente" a "En Proceso"
4. Toca "Guardar"
5. Espera confirmación: [__:__]
```

**Validación:**
- [ ] Botón de editar está habilitado
- [ ] Cambio de estado permitido
- [ ] Confirmación: "Cita actualizada"
- [ ] Cambio reflejado en pantalla

**En Firestore:**
```
Documento actualizado:
- status: "En Proceso"
- lastModified: [Timestamp reciente]
- modifiedBy: [UID de A]
```

**Resultado esperado:**
- ✅ Actualización exitosa
- ✅ Cambios visibles inmediatamente
- ✅ Firestore refleja la modificación

**Resultado observado:** ☐ Pasó | ☐ Falló  
**Evidencia:** `[Documento ID: ________________]`

---

### Prueba SEG-09: Cambio de propietario - A intenta reasignar cita
**Acción:** A intenta cambiar el UID de propietario en un documento propio  
**Esperado:** Cambio de propietario rechazado

**Procedimiento:**
```
Dispositivo A:
ESCENARIO 1: Si la app permite editar userId directamente:
1. Abre cita CITA_SEGURIDAD_A_001
2. Intenta editar campo 'userId' o 'creadoPor'
3. Cambia valor a UID de B
4. Toca "Guardar"

ESCENARIO 2: Acceso técnico:
- Intenta ejecutar:
  db.collection('appointments').doc('[ID_CITA_A]').update({
    userId: '[UID_DE_B]'
  })

Resultado observado:
- ¿Se permite el cambio?: ☐ Sí | ☐ No
- ¿Se actualiza en Firestore?: ☐ Sí (ERROR) | ☐ No (Correcto)
- Error recibido: `[________________]`

Validación en Firestore:
- userId sigue siendo: [UID de ________]
```

**Resultado esperado:**
- ✅ Campo userId NO se puede cambiar (según reglas)
- ✅ Firestore rechaza la actualización
- ✅ Error: "Permission denied" o "Validation failed"

**Resultado observado:**
- userId cambió: ☐ Sí (FALLO) | ☐ No (Pasó)
- Error recibido: `[________________]`

**Severidad si falló:** ☐ Alta

---

### Prueba SEG-10: Acceso sin autenticación
**Acción:** Cerrar sesión e intentar leer o escribir  
**Esperado:** Operación rechazada

**Procedimiento:**
```
Dispositivo A:
1. Abre menú o configuración
2. Toca "Cerrar sesión"
3. Confirma cierre: [__:__]
4. Se redirige a pantalla Login

Con sesión cerrada:
1. Intenta acceder a "Mis citas":
   ¿Se permite?:☐ Sí | ☐ No
   ¿Se redirige a login?: ☐ Sí | ☐ No

2. Acceso técnico (si es posible):
   db.collection('appointments').add({
     doctor: 'Test',
     reason: 'Prueba sin autenticación'
   })
   
   Error recibido: `[________________]`

3. Intenta lectura:
   db.collection('appointments').get()
   
   ¿Retorna datos?: ☐ Sí (ERROR) | ☐ No (Correcto)
   Error: `[________________]`
```

**Resultado esperado:**
- ✅ Lectura rechazada sin autenticación
- ✅ Escritura rechazada sin autenticación
- ✅ Usuario no autenticado redirigido a login
- ✅ Error: "Permission denied"

**Resultado observado:**
- Pantalla funciona sin autenticación: ☐ Sí (FALLO) | ☐ No (Pasó)
- Lectura bloqueada: ☐ Sí (Pasó) | ☐ No (FALLO)
- Escritura bloqueada: ☐ Sí (Pasó) | ☐ No (FALLO)

**Severidad si falló:** ☐ Crítica

---

## MATRIZ DE PRUEBAS DE SEGURIDAD

| ID | Prueba | Procedimiento | Esperado | Resultado | Severidad | Evidencia |
|---|---|---|---|---|---|---|
| SEG-01 | Login válido | Email + password correcto | Autenticación exitosa | ☐ P | - | [Cap] |
| SEG-02 | Login inválido | Password incorrecto | Acceso rechazado | ☐ P | - | [Cap] |
| SEG-03 | Creación propia | A registra cita | userId = A | ☐ P | - | [Doc] |
| SEG-04 | Suplantación | A intenta userId=B | Rechazado | ☐ P | Crítica | [Error] |
| SEG-05 | Lectura ajena | A lee cita de B | Denegada | ☐ P | Crítica | [Error] |
| SEG-06 | Actualización ajena | A modifica cita de B | Denegada | ☐ P | Crítica | [Error] |
| SEG-07 | Eliminación ajena | A elimina cita de B | Denegada | ☐ P | Crítica | [Error] |
| SEG-08 | Actualización propia | A modifica su cita | Permitida | ☐ P | - | [Doc] |
| SEG-09 | Cambio propietario | A intenta reasignar | Rechazado | ☐ P | Alta | [Error] |
| SEG-10 | Sin autenticación | Cerrar sesión y acceder | Bloqueado | ☐ P | Crítica | [Error] |

**Leyenda:** P = Pasó | F = Falló

---

## DEFECTOS DE SEGURIDAD ENCONTRADOS

### Defecto Crítico [CRI-001]
**Título:** [Descripción]  
**Tipo:** Autenticación | Autorización | Validación  
**Severidad:** ☐ Crítica | ☐ Alta | ☐ Media | ☐ Baja  
**Reproducer:**
```
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]
```
**Resultado observado:** [Qué pasó]  
**Resultado esperado:** [Qué debería pasar]  
**Riesgo de seguridad:** [Impacto potencial]  
**Corrección:** [Cómo se puede resolver]  
**Estado:** [ ] Abierto | [ ] En revisión | [ ] Cerrado  

---

## ANÁLISIS Y CONCLUSIONES

### Resumen de Resultados
- Total de pruebas: 10
- Pasadas: [ ] / 10
- Fallidas: [ ] / 10
- Tasa de éxito: [ ]%

### Defectos Críticos Encontrados
- [ ] 0 defectos | [ ] 1-2 defectos | [ ] 3+ defectos

### Defectos Altos Encontrados
- [ ] 0 defectos | [ ] 1-2 defectos | [ ] 3+ defectos

### Riesgos de Seguridad Identificados
1. ☐ Usuario puede acceder a datos ajenos
2. ☐ Usuario puede modificar datos ajenos
3. ☐ Usuario sin autenticación puede acceder
4. ☐ Campo 'userId' puede ser manipulado
5. ☐ Reglas de Firestore no son restrictivas
6. ☐ Falta validación en cliente
7. ☐ Falta validación en servidor
8. ☐ No hay encriptación de datos sensibles
9. ☐ No hay auditoría de cambios
10. ☐ No hay rate limiting contra ataques

### Recomendaciones de Corrección
1. **Validación en Cliente:** Ocultar botones y campos según rol y permisos
2. **Validación en Servidor:** Las reglas de Firestore son la defensa principal
3. **Auditoría:** Registrar quién, qué y cuándo
4. **Encriptación:** Datos sensibles deben encriptarse
5. **Rate Limiting:** Prevenir ataques de fuerza bruta

### Apto para Producción
- [ ] ✅ Sí - Sin defectos críticos
- [ ] ⚠️ Condicionalmente - Defectos altos corregidos
- [ ] ❌ No - Defectos críticos encontrados

**Justificación:**
```
[Resumen ejecutivo de la postura de seguridad]
```

---

## RESPUESTAS A PREGUNTAS DE REFLEXIÓN

### 1. ¿Por qué no es suficiente ocultar en la interfaz los botones de editar o eliminar?

**Respuesta:**
```
[El usuario puede responder basándose en las pruebas ejecutadas]

Un usuario malintencionado puede:
- Inspeccionar el código cliente (DevTools)
- Modificar solicitudes HTTP/Firestore
- Usar herramientas de debugging
- Llamar directamente a APIs de Firestore

Por lo tanto, la seguridad debe estar en el servidor (Firestore Rules),
no solo en la interfaz.
```

---

### 2. ¿Cuál es la diferencia entre autenticación y autorización?

**Respuesta:**
```
AUTENTICACIÓN: ¿Eres quién dices ser?
- Verificar identidad (Email + Contraseña)
- Resultado: Usuario autenticado (UID conocido)
- Responsable: Firebase Authentication

AUTORIZACIÓN: ¿Qué puedes hacer?
- Verificar permisos (¿Puedes leer/escribir este documento?)
- Basado en el UID autenticado
- Responsable: Firestore Security Rules

Ejemplo:
- Autenticación: "Eres usuario.a@medicontrol.test"
- Autorización: "Pero solo puedes ver tus propias citas"
```

---

### 3. ¿Qué riesgo existe si la aplicación permite que el cliente envíe cualquier valor en 'creadoPor'?

**Respuesta:**
```
RIESGO: Suplantación de identidad

Si el cliente puede enviar cualquier UID en 'creadoPor':

1. Crearía un documento con UID falso
   db.collection('appointments').add({
     creadoPor: 'UID_de_otro_usuario',
     ...
   })

2. Podría:
   - Culpar falsamente a otro usuario
   - Acceder a datos si las reglas confían en 'creadoPor'
   - Romper auditoría y trazabilidad

SOLUCIÓN:
- Nunca confiar en valores enviados por el cliente
- Usar request.auth.uid en las reglas (verificado por servidor)
- Asignar 'creadoPor' = request.auth.uid automáticamente
```

---

### 4. ¿Por qué las reglas deben comprobar el UID del usuario autenticado y no confiar en un correo o nombre?

**Respuesta:**
```
Porque el correo y nombre PUEDEN SER MANIPULADOS por el cliente.

Vulnerabilidad:
- Cliente puede enviar email: "admin@medicont rol.test"
- Servidor no sabe si realmente es admin

UID es SEGURO porque:
- Lo genera Firebase Authentication
- No puede ser modificado por el cliente
- Es verificado por servidor automáticamente
- Cada usuario tiene un UID único e inmutable

Regla SEGURA:
allow read: if request.auth.uid == resource.data.userId;

Regla INSEGURA (NUNCA HACER):
allow read: if request.auth.token.email == resource.data.ownerEmail;
```

---

### 5. ¿Qué pruebas adicionales realizarías para validar tipos de datos y evitar campos inesperados?

**Respuesta:**
```
Pruebas adicionales:

1. VALIDACIÓN DE TIPOS
   - Enviar string en lugar de date
   - Enviar objeto en lugar de string
   - Enviar null en campos obligatorios
   
   Firestore Rules:
   allow create: if request.resource.data.date is timestamp
                 && request.resource.data.reason is string
                 && request.resource.data.status in ['Pendiente','En Proceso'];

2. CAMPOS INESPERADOS
   - Cliente intenta crear: {..., admin: true, ...}
   - Servidor debe rechazar campos no permitidos
   
   Firestore Rules:
   allow create: if request.resource.data.keys().hasAll(['doctor','date','reason'])
                 && request.resource.data.keys().size() == 5;

3. VALIDACIONES DE NEGOCIO
   - Hora fuera de rango (01:00 - 23:00)
   - Fecha pasada
   - Razón muy corta (<10 caracteres)
   
   Firestore Rules:
   allow create: if request.resource.data.date > now
                 && request.resource.data.reason.size() >= 10;

4. ATAQUES DE INYECCIÓN
   - Campos con código malicioso
   - SQL injection (si hay backend)
   - XSS en campos de texto
   
   Firestore Rules: Firestore no ejecuta código en campos
   Cliente: Sanitizar entrada antes de mostrar
```

---

### 6. ¿Cómo cambiaría el diseño si se necesitara un rol de administrador?

**Respuesta:**
```
CAMBIOS EN LA ARQUITECTURA:

1. ESTRUCTURA DE DATOS
   Agregar campo 'role' en documento 'users':
   {
     uid: "...",
     email: "...",
     role: "admin" | "user"  // NUEVO
   }

2. REGLAS DE FIRESTORE
   
   // Usuario regular: solo sus datos
   match /appointments/{appointmentId} {
     allow read: if request.auth.uid == resource.data.userId;
   }
   
   // Admin: todos los datos
   match /appointments/{appointmentId} {
     allow read: if isAdmin();
     allow update: if isAdmin();  // Sin restricción de userId
   }
   
   // Función auxiliar:
   function isAdmin() {
     return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
   }

3. INTERFAZ
   - Menú Admin Dashboard visible solo si role == 'admin'
   - Listado de todas las citas (sin filtro de usuario)
   - Opciones de editar/eliminar cualquier registro

4. AUDITORÍA
   - Registrar que un admin modificó un documento
   - Potencialmente requerir justificación

5. SEGURIDAD
   - Roles deben estar verificados en servidor
   - No confiar en claim de rol del cliente
   - Restringir acceso a funciones admin solo a UIDs específicos
```

---

### 7. ¿Qué diferencia existe entre un fallo de conectividad y una denegación por reglas de seguridad?

**Respuesta:**
```
FALLO DE CONECTIVIDAD:
- El cliente no puede alcanzar Firestore
- Error: Network error, timeout, etc.
- Causa: Sin WiFi, servidor caído
- Mensaje: "Error de conexión" o "Sin internet"
- Usuario puede: Reintentar cuando hay conexión
- Datos locales: Se pueden conservar para sincronizar después

DENEGACIÓN POR REGLAS:
- El cliente conecta a Firestore, pero las reglas RECHAZAN la operación
- Error: "Permission denied" (PERMISSION_DENIED)
- Causa: El usuario no tiene autorización
- Mensaje: "No tienes permiso para acceder a estos datos"
- Usuario puede: NO puede reintentar (está denegado por seguridad)
- Causa raíz: Reglas de Firestore o autenticación

DIFERENCIACIÓN EN CÓDIGO:
```

```javascript
// Firestore
db.collection('appointments').add({...})
  .then(() => console.log('Éxito'))
  .catch((error) => {
    if (error.code === 'permission-denied') {
      console.log('ERROR DE AUTORIZACIÓN');
      // Mostrar: "No tienes permiso para crear citas"
    } else if (error.code === 'unavailable') {
      console.log('ERROR DE CONEXIÓN');
      // Mostrar: "Sin conexión a internet"
    }
  });
```

**Resumen:**
| Aspecto | Conectividad | Seguridad |
|---|---|---|
| Causa | Red/Servidor | Permisos insuficientes |
| Error Code | unavailable, timeout | permission-denied |
| ¿Reintentar? | Sí | No |
| Mensaje | "Sin internet" | "Acceso denegado" |

---

## EVIDENCIAS FOTOGRÁFICAS

**Capturas requeridas:**

### Autenticación
- [ ] Pantalla Login (Usuario A)
- [ ] Pantalla Login (Usuario B)
- [ ] Sesión iniciada - Usuario A (mostrando email/UID)
- [ ] Sesión iniciada - Usuario B (mostrando email/UID)

### Creación de Datos
- [ ] Cita creada por A en Firestore Console
- [ ] Cita creada por B en Firestore Console
- [ ] Campo 'userId' = UID de A (en cita A)
- [ ] Campo 'userId' = UID de B (en cita B)

### Intentos No Autorizados
- [ ] Mensaje de error cuando A intenta acceder a cita de B
- [ ] Firestore Rules - Reglas publicadas
- [ ] Intento de DELETE rechazado
- [ ] Intento de UPDATE rechazado

### Finales
- [ ] Sesión cerrada (pantalla login)
- [ ] Intento de acceso sin autenticación (bloqueado)

---

## NOTAS DEL EVALUADOR

[Espacio para conclusiones, observaciones y recomendaciones finales]

