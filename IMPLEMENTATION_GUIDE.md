# 🏥 MediControl V2 - Guía de Implementación

## ✅ FASE 1: Autenticación y Roles (COMPLETADA)

### 1. **Sistema de Autenticación JWT**
- ✅ `AuthService` con login, registro y gestión de tokens
- ✅ Almacenamiento seguro de tokens en `SharedPreferences`
- ✅ Validación automática de expiración de tokens con `jwt_decoder`
- ✅ Headers HTTP con autenticación Bearer

**Ubicación:** `lib/services/auth_service.dart`

```dart
// Métodos principales:
- login(email, password) -> User + Tokens
- register(fullName, email, password, phone) -> User + Token
- logout() -> limpia datos
- getAuthHeaders() -> headers con token
- isTokenExpired() -> valida expiración
```

### 2. **Modelo de Usuario con Roles**
- ✅ Enum `UserRole` (ADMIN, DOCTOR, USER)
- ✅ Clase `User` con serialización JSON
- ✅ Almacenamiento persistente

**Ubicación:** `lib/models/user.dart`

```dart
enum UserRole { admin, doctor, user }

class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
}
```

### 3. **Provider para Gestión de Estado Global**
- ✅ `AuthProvider` con ChangeNotifier
- ✅ Manejo de estado de autenticación
- ✅ Métodos para login, registro y logout
- ✅ Propiedades computed (isAdmin, isAuthenticated)

**Ubicación:** `lib/providers/auth_provider.dart`

```dart
class AuthProvider extends ChangeNotifier {
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  
  // Métodos:
  - initialize()
  - login(email, password)
  - register(fullName, email, password, phone)
  - logout()
}
```

### 4. **Login Screen Mejorado**
- ✅ Interfaz moderna con Material 3
- ✅ Validación de campos
- ✅ Toggle entre Login y Registro
- ✅ Manejo de errores
- ✅ Estados de carga

**Ubicación:** `lib/screens/login_screen.dart`

### 5. **AppShell Dinámico por Rol**
- ✅ Rutas diferentes según `UserRole`
- ✅ NavBar adaptivo (USER vs ADMIN)
- ✅ AppBar con info del usuario y logout
- ✅ Protección de rutas

**Ubicación:** `lib/screens/app_shell.dart`

**Navegación USER:**
- Dashboard → Citas → Médicos → Emergencia → Perfil

**Navegación ADMIN:**
- Admin Dashboard → Médicos → Citas → Perfil

### 6. **Admin Dashboard**
- ✅ Panel de control con estadísticas
- ✅ Tarjetas de métricas (Usuarios, Médicos, Citas, Alertas)
- ✅ Acciones rápidas
- ✅ Diseño profesional

**Ubicación:** `lib/screens/admin/admin_dashboard_screen.dart`

### 7. **Integración con Main.dart**
- ✅ Provider inicializado en main
- ✅ HomeRouter inteligente (verifica autenticación)
- ✅ Splash screen durante inicialización
- ✅ Material 3 habilitado

**Ubicación:** `lib/main.dart`

### 8. **ApiService Mejorado**
- ✅ Headers con autenticación Bearer en todas las requests
- ✅ Soporte para token expiration
- ✅ Manejo centralizado de errores

**Ubicación:** `lib/services/api_service.dart`

---

## 🚀 FASE 2: Gestión de Usuarios Admin (EN PROGRESO)

### Tareas Pendientes:

#### 1. **Pantalla de Gestión de Usuarios**
- 📝 Ubicación: `lib/screens/admin/users_management_screen.dart`
- 📋 Funcionalidades a implementar:
  - [x] Mostrar lista de usuarios (básico)
  - [ ] Crear nuevo usuario (formulario modal)
  - [ ] Editar usuario (actualizar rol, datos)
  - [ ] Eliminar usuario (con confirmación)
  - [ ] Filtrar por rol
  - [ ] Buscar usuarios
  - [ ] Paginación

#### 2. **Pantalla de Gestión de Médicos (Admin)**
- 📝 Mejorar: `lib/screens/doctors_screen.dart`
- 📋 Agregar funcionalidades admin:
  - [ ] Ver lista completa de médicos
  - [ ] Crear médico
  - [ ] Editar datos de médico
  - [ ] Eliminar médico
  - [ ] Ver especialidades
  - [ ] Ver clínicas

#### 3. **Pantalla de Reportes**
- 📝 Nueva: `lib/screens/admin/reports_screen.dart`
- 📋 Funcionalidades:
  - [ ] Reporte de citas (cantidad, tipos)
  - [ ] Reporte de usuarios (activos, inactivos)
  - [ ] Reporte de médicos
  - [ ] Estadísticas diarias/mensuales
  - [ ] Gráficos (charts)
  - [ ] Exportar PDF

#### 4. **Pantalla de Configuración del Sistema**
- 📝 Nueva: `lib/screens/admin/settings_screen.dart`
- 📋 Funcionalidades:
  - [ ] Configurar horarios del sistema
  - [ ] Gestionar permisos
  - [ ] Ver logs del sistema
  - [ ] Backup de datos
  - [ ] Notificaciones

---

## 🔄 FASE 3: Mejoras a Base de Datos y API

### Backend Node/Express necesario:

```javascript
// Endpoints requeridos (ya parcialmente implementados):

// AUTH
POST   /api/auth/login         → { user, token, refreshToken }
POST   /api/auth/register      → { user, token, refreshToken }
POST   /api/auth/refresh       → { token }

// USERS (ADMIN)
GET    /api/admin/users        → { users[] }
POST   /api/admin/users        → crear usuario
PUT    /api/admin/users/:id    → editar usuario
DELETE /api/admin/users/:id    → eliminar usuario
GET    /api/admin/users/:id    → detalles usuario

// DOCTORS
GET    /api/doctors            → lista de médicos
POST   /api/doctors            → crear médico
PUT    /api/doctors/:id        → editar médico
DELETE /api/doctors/:id        → eliminar médico

// APPOINTMENTS
GET    /api/appointments       → citas del usuario
POST   /api/appointments       → crear cita
PUT    /api/appointments/:id   → editar cita
DELETE /api/appointments/:id   → eliminar cita

// REPORTS (ADMIN)
GET    /api/admin/reports/users
GET    /api/admin/reports/appointments
GET    /api/admin/reports/doctors

// PROFILE
GET    /api/profile            → datos del usuario autenticado
PUT    /api/profile            → actualizar perfil
```

### Base de Datos (Schema sugerido):

```sql
-- USUARIOS
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  fullName VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role ENUM('USER', 'DOCTOR', 'ADMIN') DEFAULT 'USER',
  profileImage VARCHAR(255),
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_role (role)
);

-- MÉDICOS
CREATE TABLE doctors (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT UNIQUE,
  name VARCHAR(255) NOT NULL,
  specialty VARCHAR(100),
  phone VARCHAR(20),
  email VARCHAR(255) UNIQUE,
  clinic VARCHAR(255),
  licenseNumber VARCHAR(50) UNIQUE,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE SET NULL
);

-- CITAS
CREATE TABLE appointments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT NOT NULL,
  doctorId INT NOT NULL,
  date DATETIME NOT NULL,
  reason TEXT,
  location VARCHAR(255),
  status ENUM('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED') DEFAULT 'PENDING',
  notes TEXT,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (doctorId) REFERENCES doctors(id) ON DELETE CASCADE,
  INDEX idx_userId (userId),
  INDEX idx_doctorId (doctorId),
  INDEX idx_date (date)
);

-- REGISTROS MÉDICOS
CREATE TABLE medical_records (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT NOT NULL,
  title VARCHAR(255),
  description TEXT,
  details JSON,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_userId (userId)
);

-- CONTACTOS DE EMERGENCIA
CREATE TABLE emergency_contacts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT NOT NULL,
  name VARCHAR(255),
  relation VARCHAR(100),
  phone VARCHAR(20),
  notes TEXT,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_userId (userId)
);

-- LOGS DE AUDITORÍA
CREATE TABLE audit_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT,
  action VARCHAR(255),
  entity VARCHAR(100),
  entityId INT,
  changes JSON,
  ipAddress VARCHAR(45),
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_userId (userId),
  INDEX idx_createdAt (createdAt)
);
```

---

## 📦 Dependencias Agregadas

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0
  shared_preferences: ^2.2.2
  provider: ^6.0.0           # ✅ Gestión de estado
  jwt_decoder: ^2.0.1        # ✅ Validación JWT
  intl: ^0.19.0              # ✅ Internacionalización
```

---

## 🎯 Próximos Pasos Recomendados

### 1. **Corto Plazo (Esta Semana)**
- [ ] Crear endpoints del backend para admin
- [ ] Implementar pantalla de gestión de usuarios
- [ ] Agregar CRUD completo de médicos
- [ ] Crear formularios modales para crear/editar

### 2. **Mediano Plazo (2-3 Semanas)**
- [ ] Pantalla de reportes con gráficos (usar `charts` package)
- [ ] Logs de auditoría
- [ ] Sistema de notificaciones
- [ ] Validaciones avanzadas en formularios

### 3. **Largo Plazo (1-2 Meses)**
- [ ] Exportar reportes a PDF (usar `pdf` package)
- [ ] Backups automáticos
- [ ] Sistema de permisos granulares
- [ ] Integración con servicios externos (email, SMS)
- [ ] Tests automatizados

---

## 🧪 Testing Recomendado

### Unit Tests
```dart
// test/auth_service_test.dart
test('login debe retornar User con token', () async {
  // ...
});

test('logout debe limpiar datos', () async {
  // ...
});
```

### Widget Tests
```dart
// test/login_screen_test.dart
testWidgets('LoginScreen muestra formulario', (tester) async {
  // ...
});
```

### Integration Tests
```dart
// integration_test/auth_flow_test.dart
// Flujo completo: Login → Dashboard → Logout
```

---

## 📱 Estructura de Carpetas Actual

```
lib/
├── main.dart
├── models/
│   ├── user.dart                  ✅
│   ├── user_profile.dart
│   ├── appointment.dart
│   ├── doctor.dart
│   ├── emergency_contact.dart
│   └── medical_record.dart
├── services/
│   ├── auth_service.dart          ✅
│   └── api_service.dart           ✅
├── providers/
│   └── auth_provider.dart         ✅
├── screens/
│   ├── login_screen.dart          ✅
│   ├── app_shell.dart             ✅
│   ├── dashboard_screen.dart
│   ├── appointments_screen.dart
│   ├── doctors_screen.dart
│   ├── emergency_contacts_screen.dart
│   ├── medical_records_screen.dart
│   ├── profile_screen.dart
│   ├── mobile/
│   ├── watch/
│   └── admin/
│       ├── admin_dashboard_screen.dart    ✅
│       ├── users_management_screen.dart   ✅ (básico)
│       ├── reports_screen.dart            📝 TODO
│       └── settings_screen.dart           📝 TODO
└── utils/                         📝 TODO
    ├── validators.dart
    ├── constants.dart
    └── formatters.dart
```

---

## 🔐 Seguridad

### Implementado ✅
- Tokens JWT con expiración
- Almacenamiento seguro (SharedPreferences)
- Headers de autenticación en todas las requests
- Validación de roles en frontend

### Recomendado para Backend 🔒
- Hash de contraseñas (bcrypt)
- Rate limiting en endpoints
- CORS configurado
- HTTPS en producción
- Refresh token rotation
- Middleware de validación de JWT

---

## 📊 Métricas de Implementación

| Componente | Estado | Progreso |
|-----------|--------|----------|
| Autenticación JWT | ✅ | 100% |
| Modelo de Roles | ✅ | 100% |
| Provider Global | ✅ | 100% |
| Login Screen | ✅ | 100% |
| AppShell Dinámico | ✅ | 100% |
| Admin Dashboard | ✅ | 100% |
| Gestión Usuarios | 🟡 | 20% |
| Gestión Médicos | 🟡 | 50% |
| Reportes | 📝 | 0% |
| Configuraciones | 📝 | 0% |
| Tests | 📝 | 0% |

---

## 💡 Tips Adicionales

### Pruebas Locales
```bash
# Backend debe estar en localhost:3000
# Frontend Flutter:
flutter run -d chrome
# o
flutter run -d windows
```

### Datos de Prueba
```
Admin:
- Email: admin@medicontrol.com
- Password: admin123
- Role: ADMIN

Doctor:
- Email: doctor@medicontrol.com
- Password: doctor123
- Role: DOCTOR

User:
- Email: user@medicontrol.com
- Password: user123
- Role: USER
```

---

**Última actualización:** 2026-11-06
**Versión:** 2.0.0
**Estado:** En Desarrollo
