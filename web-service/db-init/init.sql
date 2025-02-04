-- Создание таблицы пользователей
CREATE TABLE IF NOT EXISTS "user" (
    user_id SERIAL PRIMARY KEY,
    balance INT,
    name VARCHAR,
    profile_pic VARCHAR,
    history_id SERIAL
);

-- Создание таблицы комнат
CREATE TABLE IF NOT EXISTS "room" (
    room_id SERIAL PRIMARY KEY,
    owner_id SERIAL,
    name VARCHAR,
    topic VARCHAR
);

-- Создание таблицы участия
CREATE TABLE IF NOT EXISTS "participation" (
    user_id SERIAL NOT NULL,
    room_id SERIAL NOT NULL,
    PRIMARY KEY (user_id, room_id),
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES "room"(room_id) ON DELETE CASCADE
);