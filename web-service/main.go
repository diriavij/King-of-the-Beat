package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/jackc/pgx/v4"
	"io"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v4/pgxpool"
)

var db *pgxpool.Pool

var (
	clients   = make(map[*websocket.Conn]bool)
	broadcast = make(chan []byte)
	upgrader  = websocket.Upgrader{}
	mu        sync.Mutex
)

func handleConnections(w http.ResponseWriter, r *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Ошибка подключения WebSocket:", err)
		return
	}
	defer ws.Close()

	mu.Lock()
	clients[ws] = true
	mu.Unlock()

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

	w.Header().Set("Content-Type", "application/json")
	w.Write(response)

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

func keyExists(key string) bool {
	var exists bool
	err := db.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM public.user WHERE user_id = $1)", key).Scan(&exists)
	if err != nil {
		log.Println("Error checking key existence:", err)
		return true
	}
	return exists
}

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
		newUser.UserId, 1000, newUser.Name, newUser.ProfilePic,
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

func roomKeyExists(key string) bool {
	var exists bool
	err := db.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM public.room WHERE room_id = $1)", key).Scan(&exists)
	if err != nil {
		log.Println("Error checking room key existence:", err)
		return true
	}
	return exists
}

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

	tx, err := db.Begin(context.Background())
	if err != nil {
		log.Println("Error starting transaction:", err)
		http.Error(w, "Database transaction error", http.StatusInternalServerError)
		return
	}

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

	err = tx.Commit(context.Background())
	if err != nil {
		log.Println("Error committing transaction:", err)
		http.Error(w, "Error committing transaction", http.StatusInternalServerError)
		return
	}

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

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // Explicitly set 200 OK status

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

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	var count int
	err := db.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM participation WHERE room_id = $1",
		data.RoomId,
	).Scan(&count)

	if err != nil {
		log.Println("Ошибка подсчёта участников:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if count >= 6 {
		http.Error(w, "Room is full (max 6 participants)", http.StatusBadRequest)
		return
	}

	_, err = db.Exec(context.Background(), `
		INSERT INTO participation (user_id, room_id) VALUES ($1, $2)`,
		data.UserId, data.RoomId)

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
		broadcast <- response // WebSocket канал
	}(data.RoomId)
}

func startGameHandler(w http.ResponseWriter, r *http.Request) {
	var data struct {
		UserId int `json:"userId"`
		RoomId int `json:"roomId"`
	}

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	var ownerId int
	err := db.QueryRow(context.Background(),
		"SELECT owner_id FROM room WHERE room_id = $1",
		data.RoomId,
	).Scan(&ownerId)
	if err != nil {
		log.Println("Ошибка при получении комнаты:", err)
		http.Error(w, "Room not found", http.StatusNotFound)
		return
	}

	if data.UserId != ownerId {
		http.Error(w, "Only the owner can start the game", http.StatusForbidden)
		return
	}

	var count int
	err = db.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM participation WHERE room_id = $1",
		data.RoomId,
	).Scan(&count)

	if err != nil {
		log.Println("Ошибка подсчёта участников:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	if count < 3 {
		http.Error(w, "Not enough participants to start (need at least 3)", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Game started!",
	})

}

func setTopicHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /room/set-topic")

	if r.Method != http.MethodPost {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	topics := []string{"Party", "Love", "Summer", "Chill", "Workout", "Throwback"}
	topic := topics[rand.Intn(len(topics))]

	_, err := db.Exec(context.Background(), "UPDATE public.room SET topic = $1 WHERE room_id = $2", topic, roomID)
	if err != nil {
		log.Println("Error updating topic:", err)
		http.Error(w, "Failed to set topic", http.StatusInternalServerError)
		return
	}

	log.Printf("Assigned topic '%s' to room %s\n", topic, roomID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"topic": topic,
	})
}

func submitSongsHandler(w http.ResponseWriter, r *http.Request) {
	var data struct {
		UserId int `json:"userId"`
		RoomId int `json:"roomId"`
		Songs  []struct {
			TrackName  string `json:"trackName"`
			ArtistName string `json:"artistName"`
			AlbumURL   string `json:"albumUrl"`
		} `json:"songs"`
	}

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	batch := &pgx.Batch{}
	for _, song := range data.Songs {
		batch.Queue(
			`INSERT INTO song (room_id, user_id, track_name, artist_name, album_url) 
            VALUES ($1, $2, $3, $4, $5) RETURNING song_id`,
			data.RoomId, data.UserId, song.TrackName, song.ArtistName, song.AlbumURL,
		)
	}

	br := db.SendBatch(context.Background(), batch)
	defer br.Close()

	var songsWithIds []struct {
		SongID     int    `json:"songId"`
		TrackName  string `json:"trackName"`
		ArtistName string `json:"artistName"`
		AlbumURL   string `json:"albumUrl"`
	}

	for i := 0; i < len(data.Songs); i++ {
		var song struct {
			SongID     int    `json:"songId"`
			TrackName  string `json:"trackName"`
			ArtistName string `json:"artistName"`
			AlbumURL   string `json:"albumUrl"`
		}

		if err := br.QueryRow().Scan(&song.SongID, &song.TrackName, &song.ArtistName, &song.AlbumURL); err != nil {
			log.Println("Error scanning song result:", err)
			continue
		}

		songsWithIds = append(songsWithIds, song)
	}

	response, _ := json.Marshal(songsWithIds)
	w.Header().Set("Content-Type", "application/json")
	w.Write(response)
}

func markSubmissionDoneHandler(w http.ResponseWriter, r *http.Request) {
	var data struct {
		UserId int `json:"userId"`
		RoomId int `json:"roomId"`
	}

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	_, err := db.Exec(context.Background(),
		`UPDATE participation SET is_submitted = true WHERE user_id = $1 AND room_id = $2`,
		data.UserId, data.RoomId,
	)

	if err != nil {
		http.Error(w, "Failed to update submission status", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func allSubmittedHandler(w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	var allSubmitted bool
	err := db.QueryRow(context.Background(), `
		SELECT BOOL_AND(is_submitted) FROM participation WHERE room_id = $1
	`, roomID).Scan(&allSubmitted)

	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]bool{
		"allSubmitted": allSubmitted,
	})
}

func getRandomSongsHandler(w http.ResponseWriter, r *http.Request) {
	roomIdStr := r.URL.Query().Get("roomId")
	userIdStr := r.URL.Query().Get("userId")

	if roomIdStr == "" || userIdStr == "" {
		http.Error(w, "Missing parameters", http.StatusBadRequest)
		return
	}

	roomId, _ := strconv.Atoi(roomIdStr)
	userId, _ := strconv.Atoi(userIdStr)

	var participantCount int
	err := db.QueryRow(context.Background(), `
        SELECT COUNT(*) FROM participation WHERE room_id = $1
    `, roomId).Scan(&participantCount)

	if err != nil || participantCount == 0 {
		http.Error(w, "Failed to get participant count", http.StatusInternalServerError)
		return
	}

	songsPerUser := 12 / participantCount

	rows, err := db.Query(context.Background(), `
        SELECT song_id, track_name, artist_name, album_url
        FROM song
        WHERE room_id = $1 AND user_id != $2
        ORDER BY random()
        LIMIT $3
    `, roomId, userId, songsPerUser)

	if err != nil {
		http.Error(w, "Failed to fetch songs", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var songs []Track
	for rows.Next() {
		var song Track
		err := rows.Scan(&song.SongID, &song.TrackName, &song.ArtistName, &song.AlbumURL)
		if err != nil {
			log.Println("Error scanning song row:", err)
			continue
		}
		songs = append(songs, song)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(songs)
}

func getUserBalanceHandler(w http.ResponseWriter, r *http.Request) {
	userIdStr := r.URL.Query().Get("userId")
	if userIdStr == "" {
		http.Error(w, "Missing userId", http.StatusBadRequest)
		return
	}
	userId, _ := strconv.Atoi(userIdStr)

	var balance int
	err := db.QueryRow(context.Background(), `
		SELECT balance FROM "user" WHERE user_id = $1
	`, userId).Scan(&balance)
	if err != nil {
		http.Error(w, "Failed to fetch balance", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]int{"balance": balance})
}

func submitBetsHandler(w http.ResponseWriter, r *http.Request) {
	var data struct {
		RoomId int `json:"roomId"`
		UserId int `json:"userId"`
		Bets   []struct {
			SongId    int `json:"songId"`
			BetAmount int `json:"betAmount"`
		} `json:"bets"`
	}

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("Received bets: %+v\n", data)

	batch := &pgx.Batch{}
	for _, bet := range data.Bets {
		batch.Queue(
			`INSERT INTO bets (room_id, user_id, song_id, bet_amount) VALUES ($1, $2, $3, $4)`,
			data.RoomId, data.UserId, bet.SongId, bet.BetAmount, // Добавляем songId
		)
	}

	br := db.SendBatch(context.Background(), batch)
	if err := br.Close(); err != nil {
		http.Error(w, "Failed to submit bets", http.StatusInternalServerError)
		return
	}

	_, err := db.Exec(context.Background(),
		`UPDATE participation SET bets_submitted = true WHERE user_id = $1 AND room_id = $2`,
		data.UserId, data.RoomId,
	)
	if err != nil {
		http.Error(w, "Failed to mark bets as submitted", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func allBetsSubmittedHandler(w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("roomId")
	log.Println("Received /bets/all-submitted for roomId =", roomID)

	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	var allBetsSubmitted bool
	err := db.QueryRow(context.Background(), `
		SELECT BOOL_AND(bets_submitted) FROM participation WHERE room_id = $1
	`, roomID).Scan(&allBetsSubmitted)

	if err != nil {
		log.Println("Error checking bets_submitted:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	log.Printf("All bets submitted for room %s  %v\n", roomID, allBetsSubmitted)

	json.NewEncoder(w).Encode(map[string]bool{
		"allBetsSubmitted": allBetsSubmitted,
	})
}

func markBetsSubmittedHandler(w http.ResponseWriter, r *http.Request) {
	var data struct {
		RoomId int `json:"roomId"`
		UserId int `json:"userId"`
	}

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	_, err := db.Exec(context.Background(),
		`UPDATE participation SET is_submitted = true WHERE user_id = $1 AND room_id = $2`,
		data.UserId, data.RoomId,
	)

	if err != nil {
		http.Error(w, "Failed to update submission status", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

type Track struct {
	SongID     int    `json:"songId"`
	TrackName  string `json:"trackName"`
	ArtistName string `json:"artistName"`
	AlbumURL   string `json:"albumUrl"`
}

func getRandomSongsForVotingHandler(w http.ResponseWriter, r *http.Request) {
	roomIdStr := r.URL.Query().Get("roomId")
	userIdStr := r.URL.Query().Get("userId")

	if roomIdStr == "" || userIdStr == "" {
		http.Error(w, "Missing parameters", http.StatusBadRequest)
		return
	}

	roomId, _ := strconv.Atoi(roomIdStr)
	userId, _ := strconv.Atoi(userIdStr)

	log.Printf("Received request for random songs for roomId: %d, userId: %d\n", roomId, userId)

	rows, err := db.Query(context.Background(), `
        SELECT song_id, track_name, artist_name, album_url
        FROM song
        WHERE room_id = $1
        ORDER BY random()
    `, roomId)

	if err != nil {
		log.Println("Error fetching songs from DB:", err)
		http.Error(w, "Failed to fetch songs", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var songs []Track
	for rows.Next() {
		var song Track
		err := rows.Scan(&song.SongID, &song.TrackName, &song.ArtistName, &song.AlbumURL)
		if err != nil {
			log.Println("Error scanning song row:", err)
			continue
		}
		songs = append(songs, song)
	}

	log.Printf("Fetched %d songs for roomId %d\n", len(songs), roomId)

	if len(songs) == 0 {
		log.Println("No songs found for voting")
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(songs)
}

type Bet struct {
	UserId    int `json:"userId"`
	SongId    int `json:"songId"`
	BetAmount int `json:"betAmount"`
}

func submitVoteHandler(w http.ResponseWriter, r *http.Request) {
	var vote struct {
		UserId int `json:"userId"`
		SongId int `json:"songId"`
		RoomId int `json:"roomId"`
	}

	if err := json.NewDecoder(r.Body).Decode(&vote); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	_, err := db.Exec(context.Background(), `
        INSERT INTO votes (user_id, song_id, room_id) VALUES ($1, $2, $3)`,
		vote.UserId, vote.SongId, vote.RoomId)
	if err != nil {
		http.Error(w, "Error submitting vote", http.StatusInternalServerError)
		return
	}

	_, err = db.Exec(context.Background(), `
		UPDATE participation SET bets_submitted = true WHERE room_id = $1 AND user_id = $2`,
		vote.RoomId, vote.UserId)

	if err != nil {
		log.Println("Error resetting bets_submitted:", err)
		http.Error(w, "Failed to reset bets_submitted", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func getBetsForSong(w http.ResponseWriter, r *http.Request) {
	roomId := r.URL.Query().Get("roomId")
	songId := r.URL.Query().Get("songId")

	if roomId == "" || songId == "" {
		http.Error(w, "roomId and songId are required", http.StatusBadRequest)
		return
	}

	var bets []Bet
	rows, err := db.Query(context.Background(), `
        SELECT user_id, bet_amount 
        FROM bets 
        WHERE room_id = $1 AND song_id = $2
    `, roomId, songId)

	if err != nil {
		log.Println("Error fetching bets:", err)
		http.Error(w, "Error fetching bets", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var bet Bet
		err := rows.Scan(&bet.UserId, &bet.BetAmount)
		if err != nil {
			log.Println("Error scanning bet:", err)
			continue
		}
		bets = append(bets, bet)
	}

	if len(bets) == 0 {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]Bet{}) // Отправляем пустой массив
		return
	}

	response, _ := json.Marshal(bets)
	w.Header().Set("Content-Type", "application/json")
	w.Write(response)
}

func resetBetsSubmittedHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /room/reset-bets-submitted")

	if r.Method != http.MethodPost {
		http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
		return
	}

	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	roomIDInt, err := strconv.Atoi(roomID)
	if err != nil {
		log.Println("Invalid roomId:", roomID)
		http.Error(w, "Invalid roomId", http.StatusBadRequest)
		return
	}

	_, err = db.Exec(context.Background(), `
		UPDATE participation SET bets_submitted = false WHERE room_id = $1`,
		roomIDInt)

	if err != nil {
		log.Println("Error resetting bets_submitted:", err)
		http.Error(w, "Failed to reset bets_submitted", http.StatusInternalServerError)
		return
	}

	log.Printf("Successfully reset bets_submitted for roomId %d\n", roomIDInt)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "All bets_submitted reset to false for room",
	})
}

func markSongEliminated(songId int, round int) error {
	_, err := db.Exec(context.Background(), `
        UPDATE song_progress SET eliminated = true, round = $1 WHERE song_id = $2`,
		round, songId)
	return err
}

func determineWinnerAndNextRound(w http.ResponseWriter, r *http.Request) {
	song1Votes, err := getSongVotes(song1Id, roomId)
	if err != nil {
		http.Error(w, "Error", http.StatusInternalServerError)
		return
	}

	song2Votes, err := getSongVotes(song2Id, roomId)
	if err != nil {
		http.Error(w, "Error", http.StatusInternalServerError)
		return
	}

	if song1Votes > song2Votes {
		markSongEliminated(song2Id, currentRound)
	} else {
		markSongEliminated(song1Id, currentRound)
	}
	awardBets(winningSongId, roomId) // Начисление ставок
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

	http.HandleFunc("/ws", handleConnections)
	http.HandleFunc("/room/participants", getRoomParticipantsHandler)
	http.HandleFunc("/random-user-key", randomUserKeyHandler)
	http.HandleFunc("/random-room-key", randomRoomKeyHandler)
	http.HandleFunc("/rooms/create", createRoomHandler)
	http.HandleFunc("/auth/register", addUserHandler)
	http.HandleFunc("/room/info", getRoomInfo)
	http.HandleFunc("/user/info", getUserInfo)
	http.HandleFunc("/room/add-user", addUserToRoomHandler)
	http.HandleFunc("/room/start", startGameHandler)
	http.HandleFunc("/room/set-topic", setTopicHandler)
	http.HandleFunc("/songs/submit", submitSongsHandler)
	http.HandleFunc("/room/submission-done", markSubmissionDoneHandler)
	http.HandleFunc("/room/all-submitted", allSubmittedHandler)
	http.HandleFunc("/room/random-songs", getRandomSongsHandler)
	http.HandleFunc("/user/balance", getUserBalanceHandler)
	http.HandleFunc("/bets/submit", submitBetsHandler)
	http.HandleFunc("/bets/all-submitted", allBetsSubmittedHandler)
	http.HandleFunc("/bets/mark-submitted", markBetsSubmittedHandler)
	http.HandleFunc("/vote/submit", submitVoteHandler)
	http.HandleFunc("/songs/for-voting", getRandomSongsForVotingHandler)
	http.HandleFunc("/bets/for-song", getBetsForSong)
	http.HandleFunc("/room/reset-bets-submitted", resetBetsSubmittedHandler)

	go func() {
		for {
			msg := <-broadcast
			broadcastUpdates(msg)
		}
	}()

	fmt.Println("Server running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
