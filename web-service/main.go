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
	upgrader  = websocket.Upgrader{}
	clientsMu sync.Mutex
	broadcast = make(chan []byte)
)

func handleConnections(w http.ResponseWriter, r *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Ошибка подключения WebSocket:", err)
		return
	}
	defer ws.Close()

	clientsMu.Lock()
	clients[ws] = true
	clientsMu.Unlock()

	for {
		if _, _, err := ws.ReadMessage(); err != nil {
			log.Println("Соединение закрыто:", err)
			clientsMu.Lock()
			delete(clients, ws)
			clientsMu.Unlock()
			break
		}
	}
}

func broadcastUpdates(data []byte) {
	clientsMu.Lock()
	defer clientsMu.Unlock()
	for client := range clients {
		if err := client.WriteMessage(websocket.TextMessage, data); err != nil {
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
	b := make([]byte, 6)
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
		tx.Rollback(context.Background())
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
		tx.Rollback(context.Background())
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
	w.WriteHeader(http.StatusOK)

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
		broadcast <- response
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
			data.RoomId, data.UserId, bet.SongId, bet.BetAmount,
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
		json.NewEncoder(w).Encode([]Bet{})
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

func markSongEliminated(songId, round int) error {
	_, err := db.Exec(context.Background(), `
        UPDATE song 
           SET eliminated = TRUE,
               eliminated_round = $2
         WHERE song_id = $1
    `, songId, round)
	return err
}

func getSongVotes(songId int, roomId int) (int, error) {
	var count int
	err := db.QueryRow(context.Background(), `
        SELECT COUNT(*) 
          FROM votes 
         WHERE song_id = $1 AND room_id = $2
    `, songId, roomId).Scan(&count)
	if err != nil {
		log.Println("Ошибка при подсчёте голосов:", err)
		return 0, err
	}
	return count, nil
}

func awardBets(roomID int, songID int) error {
	rows, err := db.Query(context.Background(), `
        SELECT user_id, bet_amount
          FROM bets
         WHERE room_id = $1 AND song_id = $2
    `, roomID, songID)
	if err != nil {
		return fmt.Errorf("failed to query bets: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var userID, amount int
		if err := rows.Scan(&userID, &amount); err != nil {
			return fmt.Errorf("failed to scan bet row: %w", err)
		}
		if _, err := db.Exec(context.Background(), `
            UPDATE "user" 
               SET balance = balance + $1 
             WHERE user_id = $2
        `, amount*2, userID); err != nil {
			return fmt.Errorf("failed to update user balance: %w", err)
		}
	}
	return nil
}

func getCurrentRoundHandler(w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	rows, err := db.Query(context.Background(), `
        SELECT s.song_id, s.track_name, s.artist_name, s.album_url
          FROM song s
     LEFT JOIN song_progress sp ON s.song_id = sp.song_id
         WHERE s.room_id = $1
           AND (sp.eliminated IS NULL OR sp.eliminated = FALSE)
      ORDER BY random()
         LIMIT 2
    `, roomID)
	if err != nil {
		http.Error(w, "DB error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tracks []Track
	for rows.Next() {
		var t Track
		if err := rows.Scan(&t.SongID, &t.TrackName, &t.ArtistName, &t.AlbumURL); err != nil {
			continue
		}
		tracks = append(tracks, t)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tracks)
}

func initializeNextRound(roomID int) error {
	var currentRound int
	if err := db.QueryRow(context.Background(), `
        SELECT current_round 
          FROM room 
         WHERE room_id = $1
    `, roomID).Scan(&currentRound); err != nil {
		return fmt.Errorf("fetch current_round: %w", err)
	}

	nextRound := currentRound + 1

	rows, err := db.Query(context.Background(), `
        SELECT s.song_id
          FROM song s
     LEFT JOIN song_progress sp ON s.song_id = sp.song_id
         WHERE s.room_id = $1
           AND (sp.eliminated IS NULL OR sp.eliminated = FALSE)
      ORDER BY random()
         LIMIT 2
    `, roomID)
	if err != nil {
		return fmt.Errorf("select next songs: %w", err)
	}
	defer rows.Close()

	var ids []int
	for rows.Next() {
		var id int
		if err := rows.Scan(&id); err != nil {
			return fmt.Errorf("scan song_id: %w", err)
		}
		ids = append(ids, id)
	}
	if len(ids) < 2 {
		return fmt.Errorf("not enough songs remaining for next round")
	}

	if _, err := db.Exec(context.Background(), `
        UPDATE room
           SET current_round  = $2,
               current_song1 = $3,
               current_song2 = $4
         WHERE room_id = $1
    `, roomID, nextRound, ids[0], ids[1]); err != nil {
		return fmt.Errorf("update room for next round: %w", err)
	}

	return nil
}

func determineWinnerAndNextRound(roomIDStr string) error {
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		return fmt.Errorf("invalid roomId %q: %w", roomIDStr, err)
	}

	rows, err := db.Query(context.Background(), `
        SELECT s.song_id
          FROM song s
     LEFT JOIN song_progress sp ON s.song_id = sp.song_id
         WHERE s.room_id = $1
           AND (sp.eliminated IS NULL OR sp.eliminated = FALSE)
      ORDER BY random()
         LIMIT 2
    `, roomID)
	if err != nil {
		return fmt.Errorf("fetch current songs: %w", err)
	}
	defer rows.Close()

	var pair []int
	for rows.Next() {
		var id int
		if err := rows.Scan(&id); err != nil {
			return fmt.Errorf("scan song_id: %w", err)
		}
		pair = append(pair, id)
	}
	if len(pair) != 2 {
		return fmt.Errorf("need exactly 2 songs in current round, got %d", len(pair))
	}
	song1ID, song2ID := pair[0], pair[1]

	v1, err := getSongVotes(song1ID, roomID)
	if err != nil {
		return fmt.Errorf("count votes for %d: %w", song1ID, err)
	}
	v2, err := getSongVotes(song2ID, roomID)
	if err != nil {
		return fmt.Errorf("count votes for %d: %w", song2ID, err)
	}

	loser := song1ID
	switch {
	case v2 > v1:
		loser = song1ID
	case v1 > v2:
		loser = song2ID
	default:
		if rand.Intn(2) == 0 {
			loser = song1ID
		} else {
			loser = song2ID
		}
	}

	if _, err := db.Exec(context.Background(), `
    INSERT INTO song_progress (song_id, eliminated, round)
         VALUES ($1, TRUE,
                 (SELECT current_round FROM room WHERE room_id = $2) + 1)
     ON CONFLICT (song_id) DO UPDATE
          SET eliminated = TRUE,
              round     = EXCLUDED.round
`, loser, roomID); err != nil {
		return fmt.Errorf("mark eliminated: %w", err)
	}

	if err := awardBets(roomID, loser); err != nil {
		return fmt.Errorf("award bets: %w", err)
	}

	if err := initializeNextRound(roomID); err != nil {
		return fmt.Errorf("init next round: %w", err)
	}

	return nil
}

func determineWinnerHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid method, use POST", http.StatusMethodNotAllowed)
		return
	}
	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}
	if err := determineWinnerAndNextRound(roomID); err != nil {
		log.Printf("determineWinnerAndNextRound error for room %s: %v", roomID, err)
		http.Error(w, "Failed to advance round: "+err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func getTopThreeHandler(w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	rows, err := db.Query(context.Background(), `
        SELECT s.song_id, s.track_name, s.artist_name, s.album_url, COUNT(v.user_id) AS votes
          FROM song s
     LEFT JOIN votes v ON s.song_id = v.song_id AND v.room_id = $1
         WHERE s.room_id = $1
      GROUP BY s.song_id
      ORDER BY votes DESC
         LIMIT 3
    `, roomID)
	if err != nil {
		log.Println("getTopThree error:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []Track
	for rows.Next() {
		var t Track
		var votes int
		if err := rows.Scan(&t.SongID, &t.TrackName, &t.ArtistName, &t.AlbumURL, &votes); err != nil {
			log.Println("scan top three:", err)
			continue
		}
		results = append(results, t)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func getAllSongsHandler(w http.ResponseWriter, r *http.Request) {
	roomID := r.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(w, "roomId is required", http.StatusBadRequest)
		return
	}

	rows, err := db.Query(context.Background(), `
        SELECT song_id, track_name, artist_name, album_url
          FROM song
         WHERE room_id = $1
    `, roomID)
	if err != nil {
		log.Println("getAllSongs error:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var list []Track
	for rows.Next() {
		var t Track
		if err := rows.Scan(&t.SongID, &t.TrackName, &t.ArtistName, &t.AlbumURL); err != nil {
			log.Println("scan all songs:", err)
			continue
		}
		list = append(list, t)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(list)
}

func removeUserFromRoomHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost && r.Method != http.MethodDelete {
		http.Error(w, "Invalid method, use POST or DELETE", http.StatusMethodNotAllowed)
		return
	}

	roomIDStr := r.URL.Query().Get("roomId")
	userIDStr := r.URL.Query().Get("userId")
	if roomIDStr == "" || userIDStr == "" {
		http.Error(w, "roomId and userId are required", http.StatusBadRequest)
		return
	}
	roomID, err1 := strconv.Atoi(roomIDStr)
	userID, err2 := strconv.Atoi(userIDStr)
	if err1 != nil || err2 != nil {
		http.Error(w, "invalid roomId or userId", http.StatusBadRequest)
		return
	}

	if _, err := db.Exec(context.Background(),
		`DELETE FROM participation WHERE room_id = $1 AND user_id = $2`,
		roomID, userID,
	); err != nil {
		log.Printf("removeUserFromRoom error: %v", err)
		http.Error(w, "Failed to remove user from room", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"message":"removed"}`))
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
	http.HandleFunc("/currentRound", getCurrentRoundHandler)
	http.HandleFunc("/room/determine-winner", determineWinnerHandler)
	http.HandleFunc("/room/results", getTopThreeHandler)
	http.HandleFunc("/room/all-songs", getAllSongsHandler)
	http.HandleFunc("/room/remove-user", removeUserFromRoomHandler)

	go func() {
		for {
			msg := <-broadcast
			broadcastUpdates(msg)
		}
	}()

	fmt.Println("Server running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
