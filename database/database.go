package database

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// InitDB inicializa la conexión a la base de datos
func InitDB() error {
	var err error

	// Leer variables de entorno
	dbType := os.Getenv("DB_TYPE")
	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")
	sslmode := os.Getenv("DB_SSLMODE")
	if sslmode == "" {
		sslmode = "disable"
	}

	// Si no hay configuración de PostgreSQL o DB_TYPE es sqlite, usar SQLite
	if dbType == "sqlite" || host == "" || user == "" || password == "" || dbname == "" || port == "" {
		if dbname == "" {
			dbname = "api.db"
		}
		log.Println("📦 Usando SQLite para desarrollo local")
		DB, err = gorm.Open(sqlite.Open(dbname), &gorm.Config{
			Logger: logger.Default.LogMode(logger.Info),
		})
	} else {
		log.Println("🐘 Usando PostgreSQL")
		dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=UTC", host, user, password, dbname, port, sslmode)
		DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
			Logger: logger.Default.LogMode(logger.Info),
		})
	}

	if err != nil {
		return err
	}

	// Auto-migrar los modelos
	if err := DB.AutoMigrate(&User{}); err != nil {
		return err
	}

	log.Println("✅ Base de datos conectada y migrada exitosamente")
	return nil
}

// User modelo de usuario
type User struct {
	gorm.Model
	Email    string `json:"email" gorm:"unique;not null"`
	Password string `json:"password" gorm:"not null"`
	Name     string `json:"name" gorm:"not null"`
	Role     string `json:"role" gorm:"default:'user'"`
	IsActive bool   `json:"is_active" gorm:"default:true"`
}
