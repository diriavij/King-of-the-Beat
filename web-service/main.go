package main

import (
	"encoding/json"
	"net/http"
)

type Response struct {
	Message string `json:"message"`
}

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{Message: "Hello from API"})
}

func main() {
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil) // API будет работать на порту 8080
}
