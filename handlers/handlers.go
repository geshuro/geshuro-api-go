package handlers

import (
	"net/http"
	"strconv"

	"api/database"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// HealthCheck verifica el estado de la API
// @Summary Verificar estado de la API
// @Description Verifica que la API esté funcionando correctamente
// @Tags health
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /health [get]
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "OK",
		"message": "API funcionando correctamente",
		"version": "1.0.0",
	})
}

// Register registra un nuevo usuario
// @Summary Registrar nuevo usuario
// @Description Crea una nueva cuenta de usuario
// @Tags auth
// @Accept json
// @Produce json
// @Param user body RegisterRequest true "Datos del usuario"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Router /auth/register [post]
func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verificar si el usuario ya existe
	var existingUser database.User
	if err := database.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "El email ya está registrado"})
		return
	}

	// Encriptar contraseña
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al procesar la contraseña"})
		return
	}

	// Crear usuario
	user := database.User{
		Email:    req.Email,
		Password: string(hashedPassword),
		Name:     req.Name,
		Role:     "user",
		IsActive: true,
	}

	if err := database.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear el usuario"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Usuario creado exitosamente",
		"user": gin.H{
			"id":    user.ID,
			"email": user.Email,
			"name":  user.Name,
			"role":  user.Role,
		},
	})
}

// Login autentica un usuario
// @Summary Iniciar sesión
// @Description Autentica un usuario y devuelve un token
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body LoginRequest true "Credenciales de login"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Router /auth/login [post]
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Buscar usuario
	var user database.User
	if err := database.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Credenciales inválidas"})
		return
	}

	// Verificar contraseña
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Credenciales inválidas"})
		return
	}

	// Generar token JWT (simulado por ahora)
	token := "jwt_token_simulado_" + strconv.FormatUint(uint64(user.ID), 10)

	c.JSON(http.StatusOK, gin.H{
		"message": "Login exitoso",
		"token":   token,
		"user": gin.H{
			"id":    user.ID,
			"email": user.Email,
			"name":  user.Name,
			"role":  user.Role,
		},
	})
}

// GetUsers obtiene todos los usuarios
// @Summary Obtener usuarios
// @Description Obtiene la lista de todos los usuarios
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {array} database.User
// @Router /users [get]
func GetUsers(c *gin.Context) {
	var users []database.User
	if err := database.DB.Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener usuarios"})
		return
	}

	// Ocultar contraseñas
	for i := range users {
		users[i].Password = ""
	}

	c.JSON(http.StatusOK, users)
}

// GetUser obtiene un usuario específico
// @Summary Obtener usuario
// @Description Obtiene un usuario por su ID
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del usuario"
// @Success 200 {object} database.User
// @Failure 404 {object} map[string]interface{}
// @Router /users/{id} [get]
func GetUser(c *gin.Context) {
	id := c.Param("id")
	var user database.User

	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Usuario no encontrado"})
		return
	}

	user.Password = ""
	c.JSON(http.StatusOK, user)
}

// UpdateUser actualiza un usuario
// @Summary Actualizar usuario
// @Description Actualiza los datos de un usuario
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del usuario"
// @Param user body UpdateUserRequest true "Datos a actualizar"
// @Success 200 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /users/{id} [put]
func UpdateUser(c *gin.Context) {
	id := c.Param("id")
	var req UpdateUserRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user database.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Usuario no encontrado"})
		return
	}

	// Actualizar campos
	if req.Name != "" {
		user.Name = req.Name
	}
	if req.Email != "" {
		user.Email = req.Email
	}

	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al actualizar usuario"})
		return
	}

	user.Password = ""
	c.JSON(http.StatusOK, gin.H{
		"message": "Usuario actualizado exitosamente",
		"user":    user,
	})
}

// DeleteUser elimina un usuario
// @Summary Eliminar usuario
// @Description Elimina un usuario por su ID
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del usuario"
// @Success 200 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /users/{id} [delete]
func DeleteUser(c *gin.Context) {
	id := c.Param("id")
	var user database.User

	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Usuario no encontrado"})
		return
	}

	if err := database.DB.Delete(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al eliminar usuario"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Usuario eliminado exitosamente"})
}

// GetProfile obtiene el perfil del usuario autenticado
// @Summary Obtener perfil
// @Description Obtiene el perfil del usuario autenticado
// @Tags profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} database.User
// @Router /profile [get]
func GetProfile(c *gin.Context) {
	// Por simplicidad, devolvemos un perfil de ejemplo
	// En una implementación real, obtendrías el usuario del token JWT
	c.JSON(http.StatusOK, gin.H{
		"message": "Perfil del usuario",
		"profile": gin.H{
			"id":    1,
			"email": "usuario@ejemplo.com",
			"name":  "Usuario Ejemplo",
			"role":  "user",
		},
	})
}

// Estructuras para las peticiones
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name" binding:"required"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type UpdateUserRequest struct {
	Name  string `json:"name"`
	Email string `json:"email" binding:"omitempty,email"`
}
