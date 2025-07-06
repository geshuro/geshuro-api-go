# 🚀 API REST con Gin Framework

Una API REST moderna y robusta construida con **Gin**, el framework más popular y ampliamente utilizado en la industria para crear APIs en Go.

## ✨ Características

- **Gin Framework**: El framework web más rápido y popular para Go
- **GORM**: ORM moderno para manejo de base de datos
- **PostgreSQL**: Base de datos robusta y profesional (configurable para SQLite/MySQL)
- **JWT Authentication**: Autenticación segura con tokens JWT
- **Swagger Documentation**: Documentación automática de la API
- **CORS Support**: Soporte completo para CORS
- **Environment Configuration**: Configuración flexible con variables de entorno
- **Password Hashing**: Encriptación segura de contraseñas con bcrypt
- **Structured Logging**: Logging estructurado y personalizable
- **Error Handling**: Manejo robusto de errores
- **Docker Support**: Contenedorización completa con Docker y Docker Compose
- **Makefile**: Automatización de tareas de desarrollo y despliegue
- **Hot Reload**: Desarrollo con recarga automática usando Air

## 🛠️ Tecnologías Utilizadas

- **Go 1.21+**
- **Gin Framework v1.9.1**
- **GORM v1.25.5**
- **PostgreSQL** (por defecto, configurable)
- **JWT v5**
- **Swagger/OpenAPI**
- **bcrypt** para encriptación
- **Docker & Docker Compose**
- **Make** para automatización

## 📋 Prerrequisitos

- Go 1.21 o superior
- Git
- Docker (opcional, para contenedorización)
- Make (opcional, para comandos automatizados)

## 🚀 Instalación y Configuración

### Opción 1: Instalación Rápida con Make

```bash
# Clonar el repositorio
git clone <tu-repositorio>
cd api

# Instalación completa con todas las herramientas
make install

# Iniciar desarrollo (requiere PostgreSQL corriendo)
make run
```

### Opción 2: Instalación Manual

```bash
# 1. Clonar el repositorio
git clone <tu-repositorio>
cd api

# 2. Instalar dependencias
go mod tidy

# 3. Configurar variables de entorno
cp env.example .env
# Editar .env con tus configuraciones

# 4. Asegúrate de tener PostgreSQL corriendo y configurado

# 5. Ejecutar la aplicación
go run main.go
```

### Opción 3: Con Docker (recomendado)

```bash
# Clonar el repositorio
git clone <tu-repositorio>
cd api

# Construir y ejecutar con Docker Compose (API + PostgreSQL)
make docker-build
make docker-run
```

La API estará disponible en: `http://localhost:8080`

## 📚 Documentación de la API

Una vez que el servidor esté ejecutándose, puedes acceder a la documentación Swagger en:

**http://localhost:8080/swagger/index.html**

## 🔗 Endpoints Disponibles

### Rutas Públicas
- `GET /` - Página de bienvenida
- `GET /health` - Verificar estado de la API
- `POST /api/v1/auth/register` - Registrar nuevo usuario
- `POST /api/v1/auth/login` - Iniciar sesión

### Rutas Protegidas (requieren autenticación)
- `GET /api/v1/users` - Obtener todos los usuarios
- `GET /api/v1/users/:id` - Obtener usuario específico
- `PUT /api/v1/users/:id` - Actualizar usuario
- `DELETE /api/v1/users/:id` - Eliminar usuario
- `GET /api/v1/profile` - Obtener perfil del usuario

## 🔐 Autenticación

La API utiliza autenticación JWT. Para acceder a rutas protegidas:

1. Registra un usuario: `POST /api/v1/auth/register`
2. Inicia sesión: `POST /api/v1/auth/login`
3. Usa el token recibido en el header: `Authorization: Bearer <token>`

### Ejemplo de registro:
```json
{
  "email": "usuario@ejemplo.com",
  "password": "contraseña123",
  "name": "Usuario Ejemplo"
}
```

### Ejemplo de login:
```json
{
  "email": "usuario@ejemplo.com",
  "password": "contraseña123"
}
```

## 🛠️ Comandos Make Disponibles

### Desarrollo
```bash
make help              # Mostrar todos los comandos disponibles
make run               # Iniciar servidor de desarrollo
make run-air           # Iniciar con hot reload (Air)
make run-port PORT=3000 # Iniciar en puerto específico
make dev               # Entorno de desarrollo completo
make dev-full          # Setup completo con herramientas
```

### Construcción
```bash
make build             # Construir aplicación
make build-linux       # Construir para Linux
make build-macos       # Construir para macOS
make build-windows     # Construir para Windows
make prod-build        # Construir para producción
```

### Testing
```bash
make test              # Ejecutar tests
make test-coverage     # Tests con reporte de cobertura
make test-verbose      # Tests con salida verbosa
make test-race         # Tests con detección de race conditions
make test-bench        # Ejecutar benchmarks
```

### Docker
```bash
make docker-build      # Construir imagen Docker
make docker-run        # Ejecutar API solo (requiere PostgreSQL externo)
make docker-run-dev    # Ejecutar API + PostgreSQL (desarrollo completo)
make docker-stop       # Detener contenedores
make docker-logs       # Ver logs de contenedores
make docker-shell      # Abrir shell en contenedor
make docker-clean      # Limpiar recursos Docker
```

### Herramientas
```bash
make install           # Instalar todas las herramientas
make install-air       # Instalar Air para hot reload
make install-lint      # Instalar golangci-lint
make install-swag      # Instalar swag para Swagger
make lint              # Ejecutar linter
make format            # Formatear código
make swagger           # Generar documentación Swagger
```

### Utilidades
```bash
make clean             # Limpiar archivos de build
make deps              # Descargar dependencias
make health            # Verificar salud de la API
make info              # Información del proyecto
make db-reset          # Resetear base de datos
```

## 🐳 Docker

### Opción 1: API Solo (Producción)

Para ejecutar solo la API, asumiendo que PostgreSQL está disponible externamente:

```bash
# Construir imagen
make docker-build

# Ejecutar API solo
make docker-run
```

**Configuración requerida:**
- PostgreSQL debe estar disponible en `host.docker.internal:5432` (o configurar `DB_HOST`)
- Variables de entorno configuradas en `.env` o pasadas al contenedor

### Opción 2: API + PostgreSQL (Desarrollo)

Para ejecutar un entorno completo de desarrollo:

```bash
# Construir imagen
make docker-build

# Ejecutar API + PostgreSQL
make docker-run-dev
```

Esto iniciará:
- **API**: Puerto 8080
- **PostgreSQL**: Puerto 5432

### Gestión de Contenedores

```bash
# Ver logs
make docker-logs

# Detener servicios
make docker-stop

# Limpiar recursos
make docker-clean
```

### Configuración de Variables de Entorno

El contenedor de producción usa variables de entorno con valores por defecto:

```env
DB_HOST=host.docker.internal
DB_PORT=5432
DB_USER=api_user
DB_PASSWORD=api_password
DB_NAME=api
DB_SSLMODE=disable
```

Para personalizar, crea un archivo `.env` o pasa las variables al ejecutar:

```bash
DB_HOST=tu-servidor-postgres make docker-run
```

## 🏗️ Estructura del Proyecto

```
api/
├── main.go              # Punto de entrada de la aplicación
├── go.mod               # Dependencias de Go
├── go.sum               # Checksums de dependencias
├── Makefile             # Automatización de tareas
├── Dockerfile           # Configuración de Docker
├── docker-compose.yml   # Orquestación de servicios (API + PostgreSQL)
├── env.example          # Variables de entorno de ejemplo
├── .gitignore           # Archivos ignorados por Git
├── README.md            # Documentación del proyecto
├── config/
│   └── middleware.go    # Configuración de middleware
├── database/
│   └── database.go      # Configuración de base de datos y modelos
├── handlers/
│   └── handlers.go      # Manejadores de endpoints
├── routes/
│   └── routes.go        # Configuración de rutas
├── scripts/
│   ├── build.sh         # Script de construcción
│   ├── run.sh           # Script de ejecución
│   ├── test.sh          # Script de testing
│   ├── docker.sh        # Script de gestión Docker
│   └── install.sh       # Script de instalación
├── build/               # Binarios compilados
├── logs/                # Archivos de log
└── coverage/            # Reportes de cobertura
```

## 🧪 Testing

### Ejecutar Tests
```bash
make test
make test-coverage
make test-race
```

### Cobertura de Código
Los reportes de cobertura se generan en `coverage/coverage.html`

## 📦 Build para Producción

### Con Make
```bash
make prod-build
make prod-run
```

### Manual
```bash
# Build para Linux
GOOS=linux GOARCH=amd64 go build -o api main.go

# Build para macOS
GOOS=darwin GOARCH=amd64 go build -o api main.go

# Build para Windows
GOOS=windows GOARCH=amd64 go build -o api.exe main.go
```

## 🔧 Configuración Avanzada

### Cambiar Base de Datos

Para usar SQLite o MySQL, modifica `database/database.go` y las variables de entorno:

```go
// SQLite (desarrollo rápido)
// import "gorm.io/driver/sqlite"
// dsn := "api.db"
// DB, err = gorm.Open(sqlite.Open(dsn), &gorm.Config{})

// MySQL
// import "gorm.io/driver/mysql"
// dsn := "user:password@tcp(127.0.0.1:3306)/api?charset=utf8mb4&parseTime=True&loc=Local"
// DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
```

### Variables de Entorno

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `PORT` | Puerto del servidor | `8080` |
| `GIN_MODE` | Modo de Gin (debug/release) | `debug` |
| `DB_TYPE` | Tipo de base de datos | `postgres` |
| `DB_HOST` | Host de la base de datos | `localhost` |
| `DB_PORT` | Puerto de la base de datos | `5432` |
| `DB_USER` | Usuario de la base de datos | `api_user` |
| `DB_PASSWORD` | Contraseña de la base de datos | `api_password` |
| `DB_NAME` | Nombre de la base de datos | `api` |
| `DB_SSLMODE` | Modo SSL de PostgreSQL | `disable` |
| `JWT_SECRET` | Secreto para JWT | `tu_secreto_jwt_super_seguro_aqui` |
| `JWT_EXPIRATION` | Expiración del token JWT | `24h` |

### Hot Reload con Air

Para desarrollo con recarga automática:

```bash
make install-air
make run-air
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🆘 Soporte

Si tienes alguna pregunta o problema, por favor abre un issue en el repositorio.

---

**¡Disfruta construyendo APIs increíbles con Gin y PostgreSQL! 🎉** 