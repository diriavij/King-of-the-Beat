package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/jackc/pgx/v4"
)

var conn *pgx.Conn

func connectDB() {
	var err error
	conn, err = pgx.Connect(context.Background(), "postgres://user:password@postgres:5432/postgres")
	if err != nil {
		log.Fatal("Unable to connect to database:", err)
	}
	log.Println("Connected to database")
}

type Response struct {
	Message string `json:"message"`
}

func generateRandomKey() string {
	const charset = "0123456789"
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, 6) // Длина ключа — 10 символов
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}

// Проверка наличия ключа в базе данных
func keyExists(key string) bool {
	var exists bool
	err := conn.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM \"user\" WHERE user_id = $1)", key).Scan(&exists)
	if err != nil {
		log.Println("Error checking key existence:", err)
		return true // На всякий случай считаем, что ключ существует, чтобы не рисковать
	}
	return exists
}

// Обработчик
func randomUserKeyHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /random-user-key")
	if r.Method != http.MethodGet {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}
	log.Println("Generating random key...")
	for {
		randomKey := generateRandomKey()
		log.Println("Generated key:", randomKey)
		if !keyExists(randomKey) {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(randomKey)
			log.Println("Responded with key:", randomKey)
			return
		}
	}
}

type User struct {
	UserId int `json:"userId"`
}

// Обработчик добавления пользователя
func addUserHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /auth/register")

	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Println("Error reading body:", err)
		http.Error(w, "Invalid body", http.StatusBadRequest)
		return
	}
	log.Println("Request body:", string(body))

	var newUser User
	err = json.Unmarshal(body, &newUser)
	if err != nil {
		log.Println("Error decoding JSON:", err)
		http.Error(w, "Invalid JSON format", http.StatusBadRequest)
		return
	}

	// Проверяем значение userId
	if newUser.UserId == 0 {
		log.Println("Invalid userId (0 or missing)")
		http.Error(w, "userId must be a valid non-zero integer", http.StatusBadRequest)
		return
	}

	log.Printf("Adding user with ID: %d\n", newUser.UserId)

	var userID int
	err = conn.QueryRow(
		context.Background(),
		"INSERT INTO \"user\" (user_id, balance) VALUES ($1, $2) RETURNING user_id",
		newUser.UserId, 0,
	).Scan(&userID)
	if err != nil {
		log.Println("Error inserting user into database:", err)
		http.Error(w, "Error inserting user into database: "+err.Error(), http.StatusInternalServerError)
		return
	}

	log.Println("Added user with ID:", userID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id": userID,
		"message": "User added successfully",
	})
}

func main() {
	connectDB()
	defer conn.Close(context.Background())

	http.HandleFunc("/random-user-key", randomUserKeyHandler)
	http.HandleFunc("/auth/register", addUserHandler)

	fmt.Println("Server running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
