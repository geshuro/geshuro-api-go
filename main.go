package main

import (
	"log"
	"os"

	"api/config"
	"api/database"
	"api/routes"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// @title           API REST con Gin
// @version         1.0
// @description     Una API REST moderna construida con Gin framework
// @termsOfService  http://swagger.io/terms/

// @contact.name   API Support
// @contact.url    http://www.swagger.io/support
// @contact.email  support@swagger.io

// @license.name  Apache 2.0
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html

// @host      localhost:8080
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
func main() {
	// Cargar variables de entorno
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using default values")
	}

	// Configurar el modo de Gin
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Inicializar la base de datos
	if err := database.InitDB(); err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Crear el router de Gin
	router := gin.Default()

	// Configurar middleware
	config.SetupMiddleware(router)

	// Configurar rutas
	routes.SetupRoutes(router)

	// Configurar Swagger
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Obtener el puerto desde las variables de entorno
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Iniciar el servidor
	log.Printf("🚀 Servidor iniciado en http://localhost:%s", port)
	log.Printf("📚 Documentación Swagger disponible en http://localhost:%s/swagger/index.html", port)

	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
