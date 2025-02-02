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
	b := make([]byte, 6) // Длина ключа — 6 символов
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

// Обработчик генерации случайного ключа пользователя
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
	UserId     int    `json:"userId"`
	Name       string `json:"name"`
	ProfilePic string `json:"profilePic"`
}

type Room struct {
	RoomID  int    `json:"roomId"`
	OwnerID int    `json:"ownerId"`
	Name    string `json:"name"`
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
	log.Printf("Parsed user ID: %d\n", newUser.UserId)

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
		"INSERT INTO \"user\" (user_id, balance, name, profile_pic) VALUES ($1, $2, $3, $4) RETURNING user_id",
		newUser.UserId, 0, newUser.Name, newUser.ProfilePic,
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

// Проверка наличия ключа комнаты в базе
func roomKeyExists(key string) bool {
	var exists bool
	err := conn.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM room WHERE room_id = $1)", key).Scan(&exists)
	if err != nil {
		log.Println("Error checking room key existence:", err)
		return true // Считаем, что ключ существует в случае ошибки
	}
	return exists
}

// Обработчик генерации случайного ключа комнаты
func randomRoomKeyHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /random-room-key")
	if r.Method != http.MethodGet {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	log.Println("Generating random room key...")
	for {
		randomKey := generateRandomKey()
		log.Println("Generated room key:", randomKey)
		if !roomKeyExists(randomKey) {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(randomKey)
			log.Println("Responded with room key:", randomKey)
			return
		}
	}
}

// Обработчик создания комнаты
func createRoomHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /rooms/create")

	if r.Method != http.MethodPost {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	// Читаем тело запроса
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Println("Error reading body:", err)
		http.Error(w, "Invalid body", http.StatusBadRequest)
		return
	}
	log.Println("Request body:", string(body))

	var newRoom Room
	err = json.Unmarshal(body, &newRoom)
	if err != nil {
		log.Println("Error decoding JSON:", err)
		http.Error(w, "Invalid JSON format", http.StatusBadRequest)
		return
	}

	if newRoom.OwnerID == 0 || newRoom.Name == "" {
		log.Println("Invalid data: ownerId or name is missing")
		http.Error(w, "ownerId and name are required", http.StatusBadRequest)
		return
	}

	// Начинаем транзакцию
	tx, err := conn.Begin(context.Background())
	if err != nil {
		log.Println("Error starting transaction:", err)
		http.Error(w, "Database transaction error", http.StatusInternalServerError)
		return
	}

	// Вставляем комнату в базу данных
	var roomID int
	err = tx.QueryRow(
		context.Background(),
		"INSERT INTO room (room_id, owner_id, name) VALUES ($1, $2, $3) RETURNING room_id",
		newRoom.RoomID, newRoom.OwnerID, newRoom.Name,
	).Scan(&roomID)

	if err != nil {
		log.Println("Error inserting room into database:", err)
		tx.Rollback(context.Background()) // Откатываем транзакцию в случае ошибки
		http.Error(w, "Error inserting room into database: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println("Room created with ID:", roomID)

	// Добавляем владельца комнаты в participation
	_, err = tx.Exec(
		context.Background(),
		"INSERT INTO participation (user_id, room_id) VALUES ($1, $2)",
		newRoom.OwnerID, roomID,
	)

	if err != nil {
		log.Println("Error inserting owner into participation:", err)
		tx.Rollback(context.Background()) // Откатываем транзакцию в случае ошибки
		http.Error(w, "Error adding owner to participation: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println("✅ Owner added to participation: UserID", newRoom.OwnerID, "-> RoomID", roomID)

	// Фиксируем транзакцию
	err = tx.Commit(context.Background())
	if err != nil {
		log.Println("Error committing transaction:", err)
		http.Error(w, "Error committing transaction", http.StatusInternalServerError)
		return
	}

	// Отправляем успешный ответ
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"room_id": roomID,
		"message": "Room created successfully, owner added to participation",
	})
}

func getUserInfo(w http.ResponseWriter, r *http.Request) {

}

func getRoomInfo(w http.ResponseWriter, r *http.Request) {

}

func main() {
	connectDB()
	defer conn.Close(context.Background())

	http.HandleFunc("/random-user-key", randomUserKeyHandler) // Генерация ключа пользователя
	http.HandleFunc("/random-room-key", randomRoomKeyHandler) // Генерация ключа комнаты
	http.HandleFunc("/rooms/create", createRoomHandler)       // Создание комнаты
	http.HandleFunc("/auth/register", addUserHandler)         // Регистрация пользователя
	http.HandleFunc("/room", randomUserKeyHandler)
	http.HandleFunc("/user", randomRoomKeyHandler)

	fmt.Println("Server running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
