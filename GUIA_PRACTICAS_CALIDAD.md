# PRÁCTICAS DE ASEGURAMIENTO DE CALIDAD - MediControl V2
## Guía de Implementación de Pruebas de Software

**Proyecto:** MediControl V2 - Sistema de Gestión Médica con Firebase  
**Asignatura:** Aseguramiento de Calidad de Software  
**Fecha de Elaboración:** Noviembre 2026

---

## 📋 Índice de Prácticas

### [PRÁCTICA 8: Evaluación de Calidad mediante Pruebas de Caja Negra](PRACTICA_8_BLACK_BOX_TESTING.md)
**Objetivo:** Verificar que el software cumple con los requisitos especificados sin conocer su estructura interna.

**Contenido:**
- ✅ 12 requisitos verificables documentados
- ✅ 4 requisitos de operaciones principales
- ✅ 3 requisitos de validaciones
- ✅ 2 requisitos de persistencia y consistencia
- ✅ 2 requisitos de navegación, roles y permisos
- ✅ 1 requisito de manejo de errores
- ✅ Matriz de pruebas completa
- ✅ Procedimientos de verificación paso a paso

**Módulos Evaluados:**
- Autenticación (login/logout)
- Perfil de usuario (CRUD)
- Citas médicas (crear, listar, filtrar, modificar)
- Registros médicos (crear, consultar, eliminar)
- Contactos de emergencia
- Panel de administración

**Tiempo Estimado:** 2-3 horas

**[→ Ir a Práctica 8](PRACTICA_8_BLACK_BOX_TESTING.md)**

---

### [PRÁCTICA 9: Sincronización de Base de Datos entre Dispositivos](PRACTICA_9_SINCRONIZACION_DB.md)
**Objetivo:** Validar que múltiples dispositivos se conecten a la misma base de datos compartida y sincnicen correctamente los cambios.

**Contenido:**
- ✅ 6 Fases de prueba estructuradas
- ✅ 9 Casos de prueba (DB-01 a DB-09)
- ✅ Verificación de conectividad
- ✅ Pruebas de escritura/lectura cruzada
- ✅ Pruebas de actualización y sincronización
- ✅ Escenarios de conflictos y ediciones simultáneas
- ✅ Pruebas de persistencia
- ✅ Manejo de pérdida de conexión

**Requisitos:**
- 2 dispositivos Android (smartphones o emuladores)
- Mismo proyecto Firebase (medicontrolv2)
- Conexión a internet/WiFi

**Escenarios Cubiertos:**
1. Dispositivo A crea cita → Dispositivo B la ve
2. Dispositivo B crea cita → Dispositivo A la ve
3. Modificación en A se propaga a B
4. Ediciones simultáneas (conflictos)
5. Persistencia tras cerrar/abrir app
6. Manejo de interrupciones de conexión

**Tiempo Estimado:** 1.5-2 horas

**[→ Ir a Práctica 9](PRACTICA_9_SINCRONIZACION_DB.md)**

---

### [PRÁCTICA 10: Seguridad, Autenticación y Control de Acceso](PRACTICA_10_SEGURIDAD_ACCESO.md)
**Objetivo:** Validar que los controles de seguridad funcionan correctamente y cada usuario solo accede a datos autorizados.

**Contenido:**
- ✅ Configuración de autenticación Firebase
- ✅ Creación de cuentas de prueba
- ✅ Implementación de Firestore Security Rules
- ✅ 10 Casos de prueba de seguridad (SEG-01 a SEG-10)
- ✅ Pruebas de autorización y control de acceso
- ✅ Validación de aislamiento de datos
- ✅ 7 Preguntas de reflexión sobre seguridad

**Casos de Prueba:**
| ID | Prueba | Descripción |
|----|--------|-------------|
| SEG-01 | Login válido | Autenticación exitosa con credenciales correctas |
| SEG-02 | Login inválido | Rechazo con credenciales incorrectas |
| SEG-03 | Creación propia | Usuario crea su propio registro |
| SEG-04 | Suplantación | Intento de cambiar propietario |
| SEG-05 | Lectura ajena | Intento de leer datos de otro usuario |
| SEG-06 | Actualización ajena | Intento de modificar datos de otro usuario |
| SEG-07 | Eliminación ajena | Intento de eliminar datos de otro usuario |
| SEG-08 | Actualización propia | Modificación de datos propios (permitido) |
| SEG-09 | Cambio de propietario | Intento de reasignar propietario |
| SEG-10 | Sin autenticación | Acceso sin iniciar sesión |

**Reglas de Firestore Incluidas:**
```javascript
// Usuarios solo acceden sus datos
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow create: if request.auth.uid == request.resource.data.uid;
  allow update: if request.auth.uid == userId;
}

// Citas: Solo el propietario
match /appointments/{appointmentId} {
  allow read: if request.auth.uid == resource.data.userId;
  allow create: if request.auth.uid == request.resource.data.userId;
  allow update: if request.auth.uid == resource.data.userId;
  allow delete: if request.auth.uid == resource.data.userId;
}
```

**Tiempo Estimado:** 2-2.5 horas

**[→ Ir a Práctica 10](PRACTICA_10_SEGURIDAD_ACCESO.md)**

---

## 🎯 Cómo Usar Esta Guía

### Paso 1: Preparación
```
1. Descargar/clonar MediControl V2 del repositorio
2. Instalar la app en dispositivo físico o emulador
3. Asegurar conectividad a Firebase
4. Crear cuentas de prueba (si es necesario)
```

### Paso 2: Ejecutar Prácticas en Orden
```
ORDEN RECOMENDADO:
1. Práctica 8 (Black Box Testing) - Funcionalidades principales
2. Práctica 9 (Sincronización DB) - Multi-dispositivo
3. Práctica 10 (Seguridad) - Control de acceso
```

### Paso 3: Documentar Resultados
```
Para cada práctica:
1. Llenar matriz de pruebas con resultados
2. Capturar pantallazos de evidencia
3. Anotar defectos encontrados
4. Generar reporte con conclusiones
```

### Paso 4: Análisis y Conclusión
```
1. Calcular tasas de éxito/fallo
2. Categorizar defectos por severidad
3. Identificar riesgos pendientes
4. Proponer mejoras al software
```

---

## 📊 Matriz de Requisitos Verificables

### Práctica 8: Black Box Testing
**Total de Requisitos:** 12

| Categoría | ID | Cantidad | Requisitos |
|-----------|----|-----------|----|
| Operaciones Principales | REQ-01-04 | 4 | Crear cita, Editar perfil, Filtrar, Eliminar |
| Validaciones | REQ-05-07 | 3 | Formato teléfono, Fecha futura, Longitud texto |
| Persistencia | REQ-08-09 | 2 | Cierre sesión, Sincronización multi-dispositivo |
| Navegación/Roles | REQ-10-11 | 2 | Permisos por rol, Aislamiento datos |
| Manejo de Errores | REQ-12 | 1 | Error de conexión |

### Práctica 9: Sincronización DB
**Total de Casos:** 9

- DB-01: Conexión compartida
- DB-02: Escritura desde A
- DB-03: Lectura desde B
- DB-04: Escritura desde B
- DB-05: Lectura desde A
- DB-06: Actualización cruzada
- DB-07: Conflicto concurrente
- DB-08: Persistencia
- DB-09: Pérdida de conexión

### Práctica 10: Seguridad
**Total de Casos:** 10

- SEG-01 a SEG-10 (Ver tabla anterior)

---

## 🛠️ Herramientas Requeridas

### Hardware
- [ ] 1-2 dispositivos Android (físicos o emuladores)
- [ ] Conexión a WiFi/Internet
- [ ] Android Studio (para emuladores)
- [ ] Adb (Android Debug Bridge)

### Software
- [ ] Flutter SDK instalado
- [ ] MediControl V2 compilada y funcional
- [ ] Firebase Console (acceso a proyecto medicontrolv2)
- [ ] Navegador web (para Firebase Console)
- [ ] Editor de texto/IDE para documentar

### Acceso
- [ ] Proyecto Firebase: medicontrolv2
- [ ] Colecciones Firestore: users, appointments, medicalRecords, emergencyContacts, doctors
- [ ] Credenciales de prueba (correos y contraseñas)

---

## 📝 Plantillas Incluidas

Cada práctica incluye:

1. **Matriz de Pruebas** - Para registrar resultados de cada caso
2. **Procedimientos Paso a Paso** - Instrucciones claras y verificables
3. **Espacios para Capturas** - Evidencia fotográfica de resultados
4. **Plantilla de Defectos** - Reportar errores encontrados
5. **Sección de Análisis** - Conclusiones y recomendaciones

---

## 🔍 Indicadores de Éxito

### Práctica 8
- ✅ Todos los requisitos documentados y verificables
- ✅ Matriz de pruebas completa con resultados
- ✅ Capturas de pantalla de validaciones
- ✅ Defectos categorizados por severidad

### Práctica 9
- ✅ Conectividad verificada en ambos dispositivos
- ✅ Propagación de cambios confirmada
- ✅ Conflictos manejados según política definida
- ✅ Persistencia de datos validada

### Práctica 10
- ✅ Autenticación funcionando
- ✅ Autorización bloqueando accesos no permitidos
- ✅ Firestore Rules implementadas
- ✅ 10/10 casos de prueba ejecutados

---

## ⚠️ Defectos Críticos a Buscar

### Críticos (Detienen la liberación)
- [ ] Usuario A puede ver datos de Usuario B
- [ ] Usuario A puede modificar datos de Usuario B
- [ ] Usuario sin autenticación puede acceder a datos
- [ ] Cambios no se sincronizaban entre dispositivos
- [ ] Falsa confirmación de guardado (error silencioso)

### Altos (Deben corregirse)
- [ ] Validaciones insuficientes
- [ ] Mensajes de error no informativos
- [ ] Campos sensibles sin encriptación
- [ ] Sin indicador de sincronización
- [ ] Performance pobre en lista grandes

### Medios (Mejora deseable)
- [ ] UI/UX no intuitiva
- [ ] Falta de confirmaciones
- [ ] Tiempos de carga subóptimos
- [ ] Documentación incompleta

---

## 📚 Recursos Adicionales

### Documentación del Proyecto
- `README.md` - Descripción general
- `IMPLEMENTATION_GUIDE.md` - Guía de implementación técnica
- `STATUS.md` - Estado de desarrollo actual

### Documentación Externa
- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Android Testing Guide](https://developer.android.com/training/testing)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

---

## 📧 Contacto y Dudas

**Para dudas sobre las prácticas:**
1. Revisar la sección correspondiente en el documento
2. Verificar matriz de pruebas para ejemplos
3. Consultar preguntas frecuentes (si aplica)

**Para reportar defectos encontrados:**
1. Usar formato de plantilla de defectos
2. Incluir pasos para reproducir
3. Adjuntar capturas de pantalla
4. Indicar severidad e impacto

---

## ✅ Checklist de Entrega

**Antes de presentar las prácticas, verificar:**

- [ ] Práctica 8
  - [ ] 12 requisitos documentados
  - [ ] Matriz de pruebas completa
  - [ ] Capturas de validaciones
  - [ ] Reporte de defectos (si aplica)
  - [ ] Conclusión y recomendaciones

- [ ] Práctica 9
  - [ ] 6 fases ejecutadas
  - [ ] 9 casos probados
  - [ ] Matriz DB completada
  - [ ] Tiempos de propagación medidos
  - [ ] Defectos de sincronización documentados

- [ ] Práctica 10
  - [ ] 2 cuentas de prueba creadas
  - [ ] Firestore Rules implementadas
  - [ ] 10 casos de seguridad ejecutados
  - [ ] 7 preguntas respondidas
  - [ ] Conclusión sobre postura de seguridad

---

## 🎓 Objetivos de Aprendizaje

Al completar estas prácticas, el estudiante podrá:

✅ **Práctica 8:**
- Identificar requisitos de software
- Diseñar casos de prueba basados en requisitos
- Ejecutar pruebas de caja negra
- Documentar resultados de pruebas

✅ **Práctica 9:**
- Validar sincronización de datos entre dispositivos
- Identificar problemas de consistencia
- Documentar comportamiento de base de datos remota
- Manejar conflictos de ediciones concurrentes

✅ **Práctica 10:**
- Implementar controles de autenticación
- Configurar reglas de autorización
- Validar aislamiento de datos
- Identificar vulnerabilidades de seguridad

---

## 📄 Versión y Historial

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | Nov 2026 | Creación inicial - Prácticas 8, 9 y 10 |

---

**Última actualización:** Noviembre 2026

**Estado:** Listo para usar

**Contacto:** [edurmz51@gmail.com]

