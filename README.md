# 🏥 MediControl V2

Aplicación de gestión médica con **roles de usuario** (Admin, Doctor, User) construida en **Flutter** con **Node.js/Express** backend.

**Estado:** ✅ FASE 1 Completada - Autenticación y Roles Implementados

## ✨ Características Principales (V2)

### 🔐 Autenticación & Seguridad
- ✅ Login/Registro con JWT
- ✅ Almacenamiento seguro de tokens en SharedPreferences
- ✅ Validación automática de expiración
- ✅ Headers Bearer en todas las requests API
- ✅ Persistencia de sesión

### 👥 Roles & Permisos
- ✅ **Admin** - Gestión completa del sistema
- ✅ **Doctor** - Perfil profesional
- ✅ **User** - Acceso a funcionalidades básicas

### 🎨 Interfaz Dinámmica
- ✅ NavBar adaptivo por rol
- ✅ Pantallas específicas según usuario
- ✅ Admin Dashboard con estadísticas
- ✅ Responsive design (Mobile, Tablet, Web, Watch)

### 📋 Gestión Médica
- ✅ Citas médicas
- ✅ Base de datos de médicos
- ✅ Registros médicos
- ✅ Contactos de emergencia

## 🚀 Quick Start

### Requisitos
- Flutter 3.x
- Node.js 16+
- MySQL 5.7+
- Git

### 1. Backend Setup (Node.js/MySQL)

```bash
# Crear y configurar backend
mkdir backend && cd backend
npm init -y
npm install express jsonwebtoken bcryptjs mysql2 cors dotenv

# Copiar archivo de ejemplo
cp ../BACKEND_EXAMPLE.js server.js

# Crear .env con tu configuración
cat > .env << EOF
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=medicontrol
JWT_SECRET=tu_secreto_super_seguro_aqui
REFRESH_SECRET=tu_refresh_secret_aqui
PORT=3000
EOF

# Crear base de datos
mysql -u root < schema.sql

# Ejecutar servidor
node server.js
```

### 2. Frontend Setup (Flutter)

```bash
# En la raíz del proyecto
flutter pub get
flutter run -d chrome    # Web
# flutter run -d windows  # Windows
# flutter run -d android  # Android
```

### 3. Test de Conexión

Verificar que el servidor esté corriendo:
```bash
curl http://localhost:3000/api/health
```

## 📝 Credenciales de Prueba

```
👨‍💼 Admin:
Email: admin@medicontrol.com
Password: admin123

👨‍⚕️ Doctor:
Email: doctor@medicontrol.com
Password: doctor123

👤 User:
Email: user@medicontrol.com
Password: user123
```

## 📁 Estructura del Proyecto

```
medicontrolv2/
├── lib/
│   ├── main.dart                    # Entry point con Provider
│   ├── models/
│   │   ├── user.dart                # ✅ User con roles
│   │   ├── user_profile.dart
│   │   ├── appointment.dart
│   │   ├── doctor.dart
│   │   ├── emergency_contact.dart
│   │   └── medical_record.dart
│   ├── services/
│   │   ├── auth_service.dart        # ✅ Autenticación JWT
│   │   └── api_service.dart         # ✅ API con headers Auth
│   ├── providers/
│   │   └── auth_provider.dart       # ✅ Estado global
│   ├── screens/
│   │   ├── login_screen.dart        # ✅ Login + Registro
│   │   ├── app_shell.dart           # ✅ Router dinámico por rol
│   │   ├── dashboard_screen.dart
│   │   ├── appointments_screen.dart
│   │   ├── doctors_screen.dart
│   │   ├── emergency_contacts_screen.dart
│   │   ├── medical_records_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── mobile/
│   │   ├── watch/
│   │   └── admin/
│   │       ├── admin_dashboard_screen.dart      # ✅ Panel Admin
│   │       ├── users_management_screen.dart     # 🟡 Básico
│   │       ├── reports_screen.dart              # 📝 TODO
│   │       └── settings_screen.dart             # 📝 TODO
│   └── utils/
│       ├── validators.dart
│       ├── constants.dart
│       └── formatters.dart
├── pubspec.yaml
├── IMPLEMENTATION_GUIDE.md           # 📚 Guía detallada
├── DEPLOYMENT_SUMMARY.md             # 📊 Resumen de implementación
├── BACKEND_EXAMPLE.js                # 💻 Backend template
└── README.md                          # Este archivo
```

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Guía técnica detallada de toda la implementación |
| [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) | Resumen de features completadas y próximos pasos |
| [BACKEND_EXAMPLE.js](BACKEND_EXAMPLE.js) | Código de referencia para el backend Node.js |

## 🔄 Flujo de Autenticación

```
1. Usuario ingresa credenciales
   ↓
2. AuthService.login() hace POST a /api/auth/login
   ↓
3. Backend valida y devuelve { user, token, refreshToken }
   ↓
4. AuthService guarda datos en SharedPreferences
   ↓
5. AuthProvider notifica a AppShell
   ↓
6. Router inteligente navega según rol del usuario
```

## 🔐 Seguridad

### Implementado ✅
- JWT con expiración
- Headers Bearer en requests
- Validación de roles en frontend
- Almacenamiento seguro de tokens

### Recomendado para Producción 🔒
- HTTPS/SSL
- Refresh token rotation
- Rate limiting
- CORS configurado
- Hashing de contraseñas (bcrypt)
- Validación en backend

## 📊 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x, Material 3 |
| **State Management** | Provider 6.x |
| **Backend** | Node.js + Express |
| **Database** | MySQL 5.7+ |
| **Authentication** | JWT (jsonwebtoken) |
| **Password** | bcryptjs |

## 📦 Dependencias Frontend

```yaml
provider: ^6.0.0           # Gestión de estado
jwt_decoder: ^2.0.1        # Validación JWT
intl: ^0.19.0              # Internacionalización
http: ^1.6.0               # HTTP requests
shared_preferences: ^2.2.2 # Almacenamiento local
```

## 🎯 Status de Features

| Feature | Status | Progress | Notas |
|---------|--------|----------|-------|
| Autenticación JWT | ✅ | 100% | Completo con login/register |
| Roles (Admin/Doctor/User) | ✅ | 100% | Enum + Model + Validación |
| Admin Dashboard | ✅ | 100% | Panel con estadísticas |
| Gestión de Usuarios | 🟡 | 20% | Lista básica, falta CRUD |
| Gestión de Médicos | 🟡 | 50% | Parcial |
| Reportes | 📝 | 0% | Pendiente |
| Sistema de Notificaciones | 📝 | 0% | Pendiente |
| Tests Automatizados | 📝 | 0% | Pendiente |
| Producción Ready | 📝 | 0% | Pendiente |

## 🚨 Troubleshooting

### Error: "Connection refused" al conectar backend
```
✓ Verificar que Node.js está ejecutándose en puerto 3000
✓ Revisar console del servidor
✓ Comprobar que .env tiene correcta configuración
```

### Error: "Token inválido" o "Session expired"
```
✓ Limpiar SharedPreferences (logout)
✓ Verificar JWT_SECRET en backend
✓ Hacer login nuevamente
```

### Error: "Database connection error"
```
✓ Verificar MySQL está corriendo
✓ Comprobar credenciales en .env
✓ Ejecutar schema.sql para crear tablas
```

### La NavBar no cambia según rol
```
✓ Verificar que UserRole enum coincide con backend response
✓ Revisar que backend devuelve 'ADMIN', 'DOCTOR' o 'USER'
✓ Comprobar que AuthProvider.currentUser tiene el rol correcto
```

## 💡 Tips de Desarrollo

### Debugging
```bash
# Ver logs en tiempo real
flutter logs

# Activar DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Hot reload
r (en consola de Flutter)
```

### Testing Backend
```bash
# Usar curl para probar endpoints
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@medicontrol.com","password":"user123"}'

# O usar Postman (importar endpoints)
```

### Ver Base de Datos
```bash
mysql -u root medicontrol
mysql> SELECT * FROM users;
mysql> SELECT * FROM appointments;
```

## 📈 Roadmap (Próximas Fases)

### FASE 2 (Esta Semana) 🟡
- [ ] Completar CRUD de usuarios (admin)
- [ ] Validaciones en formularios
- [ ] Pantalla de gestión de médicos mejorada
- [ ] Búsqueda y filtros

### FASE 3 (Próximas 2 Semanas) 📝
- [ ] Reportes con gráficos (charts package)
- [ ] Sistema de notificaciones
- [ ] Logs de auditoría
- [ ] Configuración del sistema

### FASE 4 (Este Mes) 📝
- [ ] 2FA (Two-Factor Authentication)
- [ ] Recuperación de contraseña
- [ ] Tests automatizados
- [ ] Temas (Light/Dark mode)

### FASE 5 (Próximos 2 Meses) 📝
- [ ] Exportar reportes a PDF
- [ ] Integración con email/SMS
- [ ] Backups automáticos
- [ ] Deployment a producción

## 🤝 Contribuir

Este es un proyecto en desarrollo. Para agregar features:

1. Crear rama: `git checkout -b feature/nombre`
2. Hacer cambios y commit
3. Actualizar documentación
4. Push y crear pull request

## ⚠️ Disclaimer

MediControl V2 está en fase de desarrollo. Para producción:
- ✅ Implementar todas las validaciones de seguridad
- ✅ Hacer testing exhaustivo
- ✅ Cumplir regulaciones médicas
- ✅ Implementar encriptación de datos sensibles
- ✅ Hacer auditoría de seguridad

## 📄 License

Privado - MediControl Team

## 👨‍💻 Author

Desarrollado con ❤️ para MediControl V2
**Última actualización:** 2026-11-06
**Versión:** 2.0.0 - FASE 1 ✅

---

**¡Gracias por usar MediControl! 🚀**

Para soporte, revisar documentación o crear un issue.
