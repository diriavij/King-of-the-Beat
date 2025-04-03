package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
)

var db *pgxpool.Pool

var (
	conn      *pgx.Conn
	clients   = make(map[*websocket.Conn]bool) // Храним активные WebSocket-соединения
	broadcast = make(chan []byte)              // Канал для отправки обновлений всем клиентам
	upgrader  = websocket.Upgrader{}           // Настройка WebSocket-соединения
	mu        sync.Mutex
)

// WebSocket-обработчик
func handleConnections(w http.ResponseWriter, r *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true } // Разрешаем все соединения
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Ошибка подключения WebSocket:", err)
		return
	}
	defer ws.Close()

	mu.Lock()
	clients[ws] = true
	mu.Unlock()

	// Ожидание закрытия соединения
	for {
		_, _, err := ws.ReadMessage()
		if err != nil {
			log.Println("Соединение закрыто:", err)
			mu.Lock()
			delete(clients, ws)
			mu.Unlock()
			break
		}
	}
}

// Функция отправки обновлений всем клиентам
func broadcastUpdates(data []byte) {
	mu.Lock()
	defer mu.Unlock()
	for client := range clients {
		err := client.WriteMessage(websocket.TextMessage, data)
		if err != nil {
			log.Println("Ошибка отправки сообщения:", err)
			client.Close()
			delete(clients, client)
		}
	}
}

// Обработчик получения списка участников комнаты
func getRoomParticipantsHandler(w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	rows, err := db.Query(context.Background(), `
		SELECT u.user_id, u.name, u.profile_pic 
		FROM public.participation p
		JOIN public.user u ON p.user_id = u.user_id
		WHERE p.room_id = $1`, roomID)

	if err != nil {
		log.Println("Ошибка при получении участников комнаты:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var participants []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.UserId, &user.Name, &user.ProfilePic)
		if err != nil {
			log.Println("Ошибка сканирования участников:", err)
			continue
		}
		participants = append(participants, user)
	}

	response, _ := json.Marshal(participants)

	// Отправляем ответ клиенту
	w.Header().Set("Content-Type", "application/json")
	w.Write(response)

	// Оповещаем WebSocket-клиентов о новом списке участников
	broadcastUpdates(response)
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
	err := db.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM public.user WHERE user_id = $1)", key).Scan(&exists)
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
	err = db.QueryRow(
		context.Background(),
		"INSERT INTO public.user (user_id, balance, name, profile_pic) VALUES ($1, $2, $3, $4) RETURNING user_id",
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
	err := db.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM public.room WHERE room_id = $1)", key).Scan(&exists)
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

	// Step 1: Check if the user exists in the database
	var userExists bool
	err = db.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM public.user WHERE user_id = $1)", newRoom.OwnerID).Scan(&userExists)
	if err != nil {
		log.Println("Error checking user existence:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if !userExists {
		log.Printf("Owner ID %d does not exist in user table\n", newRoom.OwnerID)
		http.Error(w, "Owner does not exist", http.StatusBadRequest)
		return
	}

	// Step 2: Begin transaction
	tx, err := db.Begin(context.Background())
	if err != nil {
		log.Println("Error starting transaction:", err)
		http.Error(w, "Database transaction error", http.StatusInternalServerError)
		return
	}

	// Step 3: Insert room into database
	var roomID int
	err = tx.QueryRow(
		context.Background(),
		"INSERT INTO public.room (room_id, owner_id, name) VALUES ($1, $2, $3) RETURNING room_id",
		newRoom.RoomID, newRoom.OwnerID, newRoom.Name,
	).Scan(&roomID)

	if err != nil {
		log.Println("Error inserting room into database:", err)
		tx.Rollback(context.Background()) // Rollback on error
		http.Error(w, "Error inserting room into database: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println("Room created with ID:", roomID)

	// Step 4: Add owner to participation
	_, err = tx.Exec(
		context.Background(),
		"INSERT INTO public.participation (user_id, room_id) VALUES ($1, $2)",
		newRoom.OwnerID, roomID,
	)

	if err != nil {
		log.Println("Error inserting owner into participation:", err)
		tx.Rollback(context.Background()) // Rollback on error
		http.Error(w, "Error adding owner to participation: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println("Owner added to participation: UserID", newRoom.OwnerID, "-> RoomID", roomID)

	// Step 5: Commit transaction
	err = tx.Commit(context.Background())
	if err != nil {
		log.Println("Error committing transaction:", err)
		http.Error(w, "Error committing transaction", http.StatusInternalServerError)
		return
	}

	// Step 6: Send success response
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
	log.Println("Received request to /room/info")

	if r.Method != http.MethodGet {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	var room Room
	err := db.QueryRow(
		context.Background(),
		"SELECT room_id, owner_id, name FROM public.room WHERE room_id = $1",
		roomID,
	).Scan(&room.RoomID, &room.OwnerID, &room.Name)

	if err != nil {
		log.Println("Error fetching room details:", err)
		http.Error(w, "Room not found", http.StatusNotFound)
		return
	}

	// Ensure correct response format
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // Explicitly set 200 OK status

	// Encode and send JSON response
	err = json.NewEncoder(w).Encode(room)
	if err != nil {
		log.Println("Error encoding JSON response:", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	}
	log.Println("Responded with room details:", room)
}

func addUserToRoomHandler(w http.ResponseWriter, r *http.Request) {
	var data struct {
		UserId int `json:"userId"`
		RoomId int `json:"roomId"`
	}

	err := json.NewDecoder(r.Body).Decode(&data)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	_, err = db.Exec(context.Background(), `
		INSERT INTO public.participation (user_id, room_id) VALUES ($1, $2)`, data.UserId, data.RoomId)

	if err != nil {
		log.Println("Ошибка при добавлении участника:", err)
		http.Error(w, "Error adding user to room", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "User successfully added to room",
	})

	go func(roomID int) {
		rows, err := db.Query(context.Background(), `
			SELECT u.user_id, u.name, u.profile_pic 
			FROM public.participation p
			JOIN public.user u ON p.user_id = u.user_id
			WHERE p.room_id = $1`, roomID)
		if err != nil {
			log.Println("Ошибка при получении участников:", err)
			return
		}
		defer rows.Close()

		var participants []User
		for rows.Next() {
			var user User
			if err := rows.Scan(&user.UserId, &user.Name, &user.ProfilePic); err != nil {
				log.Println("Ошибка сканирования участников:", err)
				continue
			}
			participants = append(participants, user)
		}

		response, _ := json.Marshal(participants)
		broadcast <- response
	}(data.RoomId)
}

func connectDB() {
	var err error
	db, err = pgxpool.Connect(context.Background(), "postgres://user:password@postgres:5432/kingofthebeat")
	if err != nil {
		log.Fatal("Unable to connect to database:", err)
	}
	log.Println("Connected to database")
}

func main() {
	connectDB()

	http.HandleFunc("/ws", handleConnections)                         // WebSocket-соединение
	http.HandleFunc("/room/participants", getRoomParticipantsHandler) // Получение участников комнаты
	http.HandleFunc("/random-user-key", randomUserKeyHandler)         // Генерация ключа пользователя
	http.HandleFunc("/random-room-key", randomRoomKeyHandler)         // Генерация ключа комнаты
	http.HandleFunc("/rooms/create", createRoomHandler)               // Создание комнаты
	http.HandleFunc("/auth/register", addUserHandler)                 // Регистрация пользователя
	http.HandleFunc("/room/info", getRoomInfo)
	http.HandleFunc("/user/info", getUserInfo)
	http.HandleFunc("/room/add-user", addUserToRoomHandler)

	go func() {
		for {
			msg := <-broadcast
			broadcastUpdates(msg)
		}
	}()

	fmt.Println("Server running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
