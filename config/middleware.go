package config

import (
	"fmt"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// SetupMiddleware configura todos los middleware necesarios para la aplicación
func SetupMiddleware(router *gin.Engine) {
	// Configurar CORS
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Length", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Middleware personalizado para logging
	router.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			param.ClientIP,
			param.TimeStamp.Format(time.RFC1123),
			param.Method,
			param.Path,
			param.Request.Proto,
			param.StatusCode,
			param.Latency,
			param.Request.UserAgent(),
			param.ErrorMessage,
		)
	}))

	// Middleware para recuperación de pánicos
	router.Use(gin.Recovery())
}

// AuthMiddleware middleware para autenticación JWT
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")
		if token == "" {
			c.JSON(401, gin.H{"error": "Token de autorización requerido"})
			c.Abort()
			return
		}

		// Aquí iría la lógica de validación del JWT
		// Por ahora solo verificamos que el token existe
		if len(token) < 7 || token[:7] != "Bearer " {
			c.JSON(401, gin.H{"error": "Formato de token inválido"})
			c.Abort()
			return
		}

		c.Next()
	}
}
