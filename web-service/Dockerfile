# Используем официальный образ Go
FROM golang:1.20

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем модуль и исходники
COPY go.mod go.sum ./
RUN go mod tidy

COPY . .

# Собираем приложение
RUN go build -o main .

# Указываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["./main"]