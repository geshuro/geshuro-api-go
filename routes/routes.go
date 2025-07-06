package routes

import (
	"net/http"

	"api/config"
	"api/handlers"

	"github.com/gin-gonic/gin"
)

// SetupRoutes configura todas las rutas de la API
func SetupRoutes(router *gin.Engine) {
	// Grupo de rutas para la API v1
	v1 := router.Group("/api/v1")
	{
		// Rutas públicas
		v1.GET("/health", handlers.HealthCheck)
		v1.POST("/auth/register", handlers.Register)
		v1.POST("/auth/login", handlers.Login)

		// Rutas protegidas
		protected := v1.Group("/")
		protected.Use(config.AuthMiddleware())
		{
			protected.GET("/users", handlers.GetUsers)
			protected.GET("/users/:id", handlers.GetUser)
			protected.PUT("/users/:id", handlers.UpdateUser)
			protected.DELETE("/users/:id", handlers.DeleteUser)
			protected.GET("/profile", handlers.GetProfile)
		}
	}

	// Ruta de bienvenida
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "🚀 Bienvenido a la API REST con Gin",
			"version": "1.0.0",
			"docs":    "/swagger/index.html",
		})
	})

	// Manejo de rutas no encontradas
	router.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Ruta no encontrada",
			"message": "La ruta solicitada no existe",
			"path":    c.Request.URL.Path,
		})
	})
}
